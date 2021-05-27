module Intrigue
  module Task
    module Enrich
      class AwsS3Bucket < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/aws_s3_bucket',
            pretty_name: 'Enrich AwsS3Bucket',
            authors: ['jcran', 'maxim'],
            description: 'Fills in details for an AwsS3Bucket (including open files)',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['AwsS3Bucket'],
            example_entities: [
              { 'type' => 'AwsS3Bucket', 'details' => { 'name' => 'bucket-name' } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          bucket_name = _get_entity_detail 'name'

          region = check_if_bucket_exists bucket_name
          return if region.nil?

          _log "Bucket lives in the #{region} region."
          _set_entity_detail 'region', region

          s3_client = initialize_s3_client bucket_name

          if s3_client # meaning we have creds
            _set_entity_detail 'belongs_to_api_key', bucket_belongs_to_api_key?(s3_client, bucket_name)
          else
            _set_entity_detail 'belongs_to_api_key', false # auto false since we can't check
          end

          bucket_objects = retrieve_public_objects s3_client, bucket_name
          return if bucket_objects.nil?

          _log_good "Found #{bucket_objects.size} object(s); attempting to filter out the public objects."

          public_objects = filter_public_objects(s3_client, bucket_name, bucket_objects)
          return if public_objects.nil?

          # here we create the issue if any files are readable
        end

        def check_if_bucket_exists(bucket_name)
          # check the region in cases where this is  to confirm the bucket does in fact exist
          region = http_request(:get, "https://#{bucket_name}.s3.amazonaws.com").headers['x-amz-bucket-region']
          if region.nil?
            _set_entity_detail 'hide', true
            _log_error 'Unable to determine region of bucket. Bucket most likely does not exist.'
            return
          end
          region
        end

        def initialize_s3_client(bucket)
          return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')

          region = _get_entity_detail 'region'
          aws_access_key = _get_task_config('aws_access_key_id')
          aws_secret_key = _get_task_config('aws_secret_access_key')
          client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)

          begin
            client.get_object({ bucket: bucket, key: "#{SecureRandom.uuid}.txt" })
          rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
            _log_error 'AWS Access Keys are not valid; will ignore keys and use unauthenticated techniques for enrichment.'
            nil
          rescue Aws::S3::Errors::NoSuchKey
            # keys are valid, we are expecting this error
            client
          end
        end

        def bucket_belongs_to_api_key?(client, bucket)
          result = false
          begin
            result = client.list_buckets['buckets'].collect(&:name).include? bucket
          rescue Aws::S3::Errors::AccessDenied
            _log 'AWS Keys do not have permission to list the buckets belonging to the account; defaulting to false.'
          end
          result
        end

        def retrieve_public_objects(client, bucket)
          bucket_objs = retrieve_objects_via_api(client, bucket) if client
          bucket_objs = retrieve_objects_via_http(bucket) if client.nil? || bucket_objs.nil?
          bucket_objs
        end

        def retrieve_objects_via_api(client, bucket)
          begin
            objs = client.list_objects_v2(bucket: bucket).contents.collect(&:key) # maximum of 1000 objects
          rescue Aws::S3::Errors::AccessDenied
            objs = []
            _log 'Could not retrieve bucket objects using the authenticated technique due to insufficient permissions.'
          end
          objs unless objs.empty? # force a nil return if an empty array as we are catching the nil reference
        end

        def retrieve_objects_via_http(bucket)
          # in this method it will try hitting the 'directory listing' and if that fails -> bruteforce common objects
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

        def filter_public_objects(s3_client, bucket, objs)
          public_objs = []

          if _get_entity_detail 'belongs_to_api_key'
            _log 'Running belongs to api key method'
            objs = objs.dup
            workers = (0...20).map do
              check = determine_public_object_via_acl(s3_client, bucket, objs, public_objs) 
              [check]
            end
            workers.flatten.map(&:join)
          end

          ### COMBINE THESE METHODS INTO 2
          if s3_client && _get_entity_detail('belongs_to_api_key').nil?
            _log 'Running belongs authenticated method'
            objs = objs.dup
            workers = (0...20).map do
              check = determine_public_object_via_api(s3_client, bucket, objs, public_objs)
              [check]
            end
            workers.flatten.map(&:join)
          end

          if s3_client.nil? || public_objs.empty?
            _log 'Running third method'
            objs = objs.dup
            workers = (0...20).map do
              check = determine_public_object_via_http(bucket, objs, public_objs)
              [check]
              end
            workers.flatten.map(&:join)
          end

          _log "Found #{public_objs.size} public object(s) that are readable."
          _log public_objs
          public_objs
        end

        # we also need to check bucket_policy to ese if objects are listable.......

        # TEST IF NO LIST PERMISSION KEYS ARE GIVEN BUT GET ARE
        def determine_public_object_via_api(client, bucket, input_q, output_q)
          t = Thread.new do
            until input_q.empty?
              while key = input_q.shift
                begin
                  client.get_object({ bucket: bucket, key: key })
                rescue Aws::S3::Errors::AccessDenied
                  key = nil
                  return t
                  # access can be denied due to various reasons including if object is encrypted using KMS and we don't have access to the key, object ACL's, etc.
                end
                output_q << key
              end
            end
          end
          t
        end

        def determine_public_object_via_http(bucket, input_q, output_q)
          # responses = make_threaded_http_requests_from_queue(work_q, 20)
          t = Thread.new do
            until input_q.empty?
              while key = input_q.shift
                r = http_request :get, "https://#{bucket}.s3.amazonaws.com/#{key}"
                output_q << key if r.code == '200'
              end
            end
          end
          t
        end

        def determine_public_object_via_acl(client, bucket, input_q, output_q)
          acl_groups = ['http://acs.amazonaws.com/groups/global/AuthenticatedUsers', 'http://acs.amazonaws.com/groups/global/AllUsers']
          t = Thread.new do
            until input_q.empty?
              while key = input_q.shift

                begin
                  obj_acl = client.get_object_acl(bucket: bucket, key: key)
                rescue Aws::S3::Errors::AccessDenied
                  return t
                end

                obj_acl.grants.each do |grant|
                  next unless acl_groups.include? grant.grantee.uri

                  output_q << key if ['READ', 'FULL_CONTROL'].include? grant.permission
                end
              end
            end
          end
          t
        end

      end
    end
  end
end
