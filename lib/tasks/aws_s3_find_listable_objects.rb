module Intrigue
  module Task
    class AwsS3BucketFindPublicObjects < BaseTask
      def self.metadata
        {
          name: 'tasks/aws_s3_find_listable_objects',
          pretty_name: 'AWS S3 Find Listable Objects',
          authors: ['maxim'],
          description: 'Searches the S3 bucket for any public objects!!!!.',
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
            { name: 'alternate_aws_api_key', regex: 'alpha_numeric_list', default: [] }
          ],
          created_types: []
        }
      end


      ## Default method, subclasses must override this
      def run
        super
        require_enrichment if _get_entity_detail('region').nil?

        bucket_name = _get_entity_detail 'name'
        s3_client = initialize_s3_client(bucket_name) if use_authentication?

        bucket_objects = retrieve_listable_objects s3_client, bucket_name
        return if bucket_objects.nil?

        _log_good "Found #{bucket_objects.size} listable object(s)."
        create_issue(bucket_name, bucket_objects)

        return unless _get_option('bruteforce_found_objects')

        # if objects are found; the bruteforce task is started to see if objects are accessible
        start_task('task', @entity.project, nil, 'tasks/aws_s3_bruteforce_objects', @entity, 1, [{ 'name' => 'objects_list', 'value' => bucket_objects.join(',') }])
      end

      def use_authentication?
        auth = _get_option('use_authentication')
        if auth && _get_entity_detail('belongs_to_api_key')
          _log 'Cannot use authentication if bucket belongs to API key as false positives will occur.'
          auth = false
        end
        auth
      end

      def initialize_s3_client(bucket)
        return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')

        region = _get_entity_detail 'region'
        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        client = api_key_valid?(client, bucket)
        client
      end

      # we originally check this is in enrichment but its worth checking again in case the keys are changed in between
      def api_key_valid?(client, bucket)
        client.get_object({ bucket: bucket, key: "#{SecureRandom.uuid}.txt" })
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        _log_error 'AWS Access Keys are not valid; will ignore keys and use unauthenticated techniques for enrichment.'
        _set_entity_detail 'belongs_to_api_key', false # auto set to false since we are unable to check
        nil
      rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied
        # keys are valid, we are expecting this error
        client
      end

      # Calls different methods based on the API Key provided to retrieve an object's listable objects
      #
      # Tries two different techniques depending on the API Key provided:
      # - Bucket not owned by API Key => Use the AWS 'authenticated' API call to attempt to list object
      # - API Key invalid or no listable objects found via API call => Use HTTP as last resort
      def retrieve_listable_objects(client, bucket)
        # if pub objs not blocked we go the api route (auth)
        bucket_objs = retrieve_objects_via_api(client, bucket) if client
        # if the api route fails (mostly due to lack permissions/or no public objects; we'll quickly try the unauth http route)
        bucket_objs = retrieve_objects_via_http(bucket) if client.nil? || bucket_objs.nil?
        bucket_objs&.reject! { |b| b =~ /.+\/$/ } # remove folder names if bucket_objs is not nil
        bucket_objs
      end

      # Attempts to retrieve the bucket's listable objects via an API call
      def retrieve_objects_via_api(client, bucket)
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
