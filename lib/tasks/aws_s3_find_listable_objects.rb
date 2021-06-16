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
            { name: 'bruteforce_found_objects', regex: 'boolean', default: true }
          ],
          created_types: []
        }
      end

      ### HANDLE IF OBJECT IS FOLDER

      ## Default method, subclasses must override this
      def run
        super
       # require_enrichment if _get_entity_detail('region').nil?
        _set_entity_detail('region', 'us-west-2') #### DEBUG

        bucket_name = _get_entity_detail 'name'
        s3_client = initialize_s3_client bucket_name

        bucket_objects = retrieve_listable_objects s3_client, bucket_name
        return if bucket_objects.nil?

        bucket_objects.reject! { |b| b =~ /.+\/$/ } # remove folder names
        _log_good "Found #{bucket_objects.size} listable object(s)."
        create_issue(bucket_name, bucket_objects)

        return unless _get_option('bruteforce_found_objects')

        start_task('task', @entity.project, nil, 'tasks/aws_s3_bruteforce_objects', @entity, 1, [{ 'name' => 'objects_list', 'value' => bucket_objects.join(',') }])
      end

      def initialize_s3_client(bucket)
        return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')

        region = _get_entity_detail 'region'
        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        client
      end

      # Calls different methods based on the API Key provided to retrieve an object's listable objects
      #
      # Tries three different techniques depending on the API Key provided:
      # - Bucket owned by API Key => Check bucket policies and ACL then check each individual object ACL
      # - Bucket not owned by API Key => Use the AWS 'authenticated' API call to attempt to list object
      # - API Key invalid or no listable objects found via API call => Use HTTP as last resort
      def retrieve_listable_objects(client, bucket)
        if _get_entity_detail 'belongs_to_api_key' # meaning bucket belongs to api key
          pub_objs_blocked = bucket_blocks_listable_objects?(client, bucket)
          return if pub_objs_blocked # all public bucket objs blocked; return
        end

        # if pub objs not blocked we go the api route (auth)
        bucket_objs = retrieve_objects_via_api(client, bucket) if client
        # if the api route fails (mostly due to lack permissions/or no public objects; we'll quickly try the unauth http route)
        bucket_objs = retrieve_objects_via_http(bucket) if client.nil? || bucket_objs.nil?
        bucket_objs
      end

      # need to rework this
      def bucket_blocks_listable_objects?(client, bucket)
        begin
          public_config = client.get_public_access_block(bucket: bucket)['public_access_block_configuration']
        rescue Aws::S3::Errors::AccessDenied
          _log 'permission error'
          return
        end

        ignore_acls = public_config['ignore_public_acls'] # this will be either true/false
        _log 'Bucket does not allow public objects; exiting.' if ignore_acls

        ignore_acls
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
