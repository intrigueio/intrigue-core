module Intrigue
  module Task
    class AwsS3BucketFindPublicObjects < BaseTask
      def self.metadata
        {
          name: 'tasks/aws_s3_find_listable_objects',
          pretty_name: 'AWS S3 Find Listable Objects',
          authors: ['maxim'],
          description: 'Searches the AWS S3 Bucket for any listable objects. If valid AWS Keys are provided, the task will use authenticated techniques to determine if the bucket is listable by any authenticated AWS user. <br><br><b>Please note:</b> if the provided AWS Keys are owned by the bucket, the task will default to using non-authenticated techniques as false positives can occur.<br><br>Task Options:<br><ul><li>bruteforce_found_objects - (default value: true) - Bruteforce the listable objects to confirm their contents are readable.</li><li>use_authentication - (default value: false) - Use authenticated techniques to attempt to list the bucket\'s objects.</ul>',
          references: [],
          type: 'enrichment',
          passive: true,
          allowed_types: ['AwsS3Bucket'],
          example_entities: [
            { 'type' => 'AwsS3Bucket', 'details' => { 'name' => 'bucket-name' } }
          ],
          allowed_options: [
            { name: 'bruteforce_found_objects', regex: 'boolean', default: true },
            { name: 'use_authentication', regex: 'boolean', default: false },
          #  { name: 'alternate_aws_api_key', regex: 'alpha_numeric_list', default: [] }
          ],
          created_types: []
        }
      end

      def run
        super
        region = bucket_enriched?
        return if region.nil?

        bucket_name = _get_entity_detail('name')

        keys = determine_aws_keys 
        s3_client = initialize_s3_client(keys['access'], keys['secret'], region) if keys # if keys exist; initalize the s3 client
        s3_client = aws_key_valid?(s3_client, bucket_name) if s3_client # if client initialized, validate keys exist

        # retrieve listable objects
        bucket_objects = retrieve_listable_objects s3_client, bucket_name
        return if bucket_objects.nil?

        _log_good "Found #{bucket_objects.size} listable object(s)."
        create_issue(bucket_name, bucket_objects)

        return unless _get_option('bruteforce_found_objects')

        # if any listable objects are found; the bruteforce task is automatically started to see if objects are accessible
        start_task('task', @entity.project, nil, 'tasks/aws_s3_bruteforce_objects', @entity, 1, [{ 'name' => 'objects_list', 'value' => bucket_objects.join(',') }])
      end


      # keeping this for now

      def determine_aws_keys
        keys = nil
        if _get_option('use_authentication')
          if _get_option('alternate_aws_api_key')
            # user provided alternative aws keys -> use them
            keys = parse_alternative_keys(_get_option('alternate_aws_api_key'))
          elsif _get_entity_detail('api_key_valid')
            # keys which are stored in task config are valid -> use them
            keys = { 'access' => _get_task_config('aws_access_key_id'), 'secret' => _get_task_config('aws_secret_access_key') }
          end
        end
        keys
      end

=begin
      def parse_alternative_keys(key_string)
        regex = /(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9]):(?<![A-Za-z0-9\/+=])[A-Za-z0-9\/+=]{40}(?![A-Za-z0-9\/+=])/
        unless key_string.match?(regex)
          _log_error 'Ignoring alternative AWS Key as its not in the correct format; should be accesskey:secretkey'
          return
        end

        key_string = key_string.split(':')
        access_key = key_string[0]
        secret_key = key_string[1]

        { 'access' => access_key, 'secret' => secret_key }
      end
=end

      # checks to see if use_authentication option has been set to true 
      # if the bucket owns the key, we return false as false positives will occur
      def use_authentication?
        auth = _get_option('use_authentication')
        if auth && _get_entity_detail('belongs_to_api_key')
          _log 'Cannot use authentication if bucket belongs to API key as false positives will occur.'
          auth = false
        end
        auth
      end

      # checks if the bucket has been enriched and if so returns the region (as its required to initalize the s3 client)
      # if bucket does not exist; we end the task abruptly as theres no point in working with a non-existent bucket
      def bucket_enriched?
        require_enrichment if _get_entity_detail('region').nil?
        region = _get_entity_detail('region')
        _log_error 'Bucket does not have a region meaning it does not exist; exiting task.' if region.nil?
        region
      end

      # Calls different methods based on the API Key provided to retrieve an object's listable objects
      #
      # Tries two different techniques depending on the API Key provided:
      # - Bucket not owned by API Key => Use the AWS 'authenticated' API call to attempt to list object
      # - API Key invalid or no listable objects found via API call => Use HTTP as last resort
      #
      # returns listable objects if any were found
      def retrieve_listable_objects(client, bucket)
        # if pub objs not blocked we go the api route (auth)
        bucket_objs = retrieve_objects_via_api(client, bucket) if client
        # if the api route fails (mostly due to lack permissions/or no public objects; we'll quickly try the unauth http route)
        bucket_objs = retrieve_objects_via_http(bucket) if client.nil? || bucket_objs.nil?
        bucket_objs&.reject! { |b| b =~ %r{.+/$} } # remove folder names if bucket_objs is not nil
        bucket_objs
      end

      # Attempts to retrieve the bucket's listable objects via an API call
      def retrieve_objects_via_api(client, bucket)
        _log 'Retrieving objects via authenticated method as keys are valid.'
        begin
          objs = client.list_objects_v2(bucket: bucket).contents.collect(&:key) # maximum of 1000 objects
        rescue Aws::S3::Errors::AccessDenied
          objs = []
          _log_error 'Could not retrieve bucket objects using the authenticated technique due to insufficient permissions.'
        end
        objs unless objs.empty? # force a nil return if an empty array as we are catching the nil reference
      end

      # Attempts to retrieve the bucket's listable objects via HTTP and parsing the XML
      def retrieve_objects_via_http(bucket)
        _log 'Retrieving objects via unauthenticated method as keys are invalid.'
        r = http_request :get, "https://#{bucket}.s3.amazonaws.com"
        if r.code != '200'
          _log 'Failed to retrieve any objects using the unauthenticated technique as bucket listing is disabled.'
          return
        end

        xml_doc = Nokogiri::XML(r.body)
        xml_doc.remove_namespaces!
        results = xml_doc.xpath('//ListBucketResult//Contents//Key').children.map(&:text)
        results[0...999] # return first 1k results as some buckets may have tons of objects
      end

      # Creates an issue if listable objects are found
      def create_issue(name, objects)
        _create_linked_issue 'aws_s3_bucket_readable', {
          proof: "#{name} lists the names of objects to any authenticated AWS user and/or everyone.",
          status: 'confirmed',
          uri: "https://#{name}.s3.amazonaws.com",
          public: true,
          details: {
            listable_objects: objects
          }
        }
      end
    end
  end
end
