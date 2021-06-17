module Intrigue
  module Task
    class AwsS3BruteforceObjects < BaseTask
      def self.metadata
        {
          name: 'tasks/aws_s3_bruteforce_objects',
          pretty_name: 'AWS S3 Bruteforce Objects',
          authors: ['maxim'],
          description: 'Bruteforces the S3 bucket for any public objects.',
          references: [],
          type: 'enrichment',
          passive: true,
          allowed_types: ['AwsS3Bucket'],
          example_entities: [
            { 'type' => 'AwsS3Bucket', 'details' => { 'name' => 'bucket-name' } }
          ],
          allowed_options: [
            { name: 'objects_list', regex: 'alpha_numeric_list', default: [] },
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

        objects_list = parse_objects
        # add seclists of 100 most common files
        return if objects_list.empty?

        bucket_name = _get_entity_detail 'name'
        s3_client = initialize_s3_client bucket_name

        public_objects = filter_public_objects(s3_client, bucket_name, objects_list)
        return if public_objects.empty?

        create_issue(bucket_name, public_objects)
      end

      def parse_objects
        objects = _get_option('objects_list').split(',')
        _log_error 'Objects list cannot be empty.' if objects.empty?
        objects
      end

      def initialize_s3_client(bucket)
        return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')

        region = _get_entity_detail 'region'
        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        client
      end


      def filter_public_objects(s3_client, bucket, objs)
        public_objs = []

        workers = (0...20).map do
          if s3_client && _get_entity_detail('belongs_to_api_key').nil?
            check = determine_public_object_via_api(s3_client, bucket, objs, public_objs)
          else
            check = determine_public_object_via_http(bucket, objs, public_objs)
          end
          [check]
        end
        workers.flatten.map(&:join)

        _log_good "Found #{public_objs.size} public object(s) that are readable."
        _log public_objs # DEBUG
        public_objs
      end

      # TEST IF NO LIST PERMISSION KEYS ARE GIVEN BUT GET ARE
      def determine_public_object_via_api(client, bucket, input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while key = input_q.shift
              begin
                client.get_object({ bucket: bucket, key: key })
              rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::NoSuchKey
                next
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

      def create_issue(name, objects)
        _create_linked_issue 'aws_s3_bucket_data_leak', {
          proof: "#{name} contains objects which are readable by any authenticated AWS user and/or everyone.",
          uri: "https://#{name}.s3.amazonaws.com",
          status: 'confirmed',
          details: {
            readable_objects: objects
          }
        }
      end

    end
  end
end
