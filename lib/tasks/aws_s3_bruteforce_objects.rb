module Intrigue
  module Task
    class AwsS3BruteforceObjects < BaseTask
      def self.metadata
        {
          name: 'tasks/aws_s3_bruteforce_objects',
          pretty_name: 'AWS S3 Bruteforce Objects',
          authors: ['maxim'],
          description: 'Bruteforces the S3 Bucket using a wordlist to find any readable objects. If valid AWS Keys are provided, the task will use authenticated techniques to attempt to read the object. <br><br><b>Please note:</b> if the bucket belongs to the provided AWS Keys, the task will default to using non-authenticated techniques as false positives will occur.<br><br>Task Options:<br><ul><li>objects_list - (default value: empty) - The list of objects to use as the wordlist. If no objects are provided, a default wordlist of 100 common files will be used.</li><li>use_authentication - (default value: false) - Use authenticated techniques to attempt to list the bucket\'s objects.</ul>',
          references: [
          'https://www.cloudconformity.com/knowledge-base/aws/S3/s3-bucket-authenticated-users-read-access.html',
          'https://www.cloudconformity.com/knowledge-base/aws/S3/s3-bucket-public-read-access.html'
          ],
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
        region = bucket_enriched?
        return if region.nil?

        bucket_name = _get_entity_detail 'bucket_name'
        objects_list = parse_objects

        keys = determine_aws_keys 
        s3_client = initialize_s3_client(keys['access'], keys['secret'], region) if keys # if keys exist; initalize the s3 client
        s3_client = aws_key_valid?(s3_client, bucket_name) if s3_client # if client initialized, validate keys exist

        readable_objects = filter_readable_objects(s3_client, bucket_name, objects_list)
        return if readable_objects.empty?

        create_issue(bucket_name, readable_objects)
      end

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

      def bucket_enriched?
        require_enrichment if _get_entity_detail('region').nil?
        region = _get_entity_detail('region')
        _log_error 'Bucket does not have a region meaning it does not exist; exiting task.' if region.nil?
        region
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

      def parse_objects
        objects = _get_option('objects_list').split(',')
        objects = File.read("#{$intrigue_basedir}/data/common_files.list").split("\n") if objects.empty?
        objects
      end


      def filter_readable_objects(s3_client, bucket, objs)
        readable_objects = []

        workers = (0...20).map do
          if s3_client && _get_entity_detail('belongs_to_api_key').nil?
            check = determine_public_object_via_api(s3_client, bucket, objs, readable_objects)
          else
            # WHAT IF THE API KEY HAS RESTRICTED PERMISSIONS? CAN WE SOMEHOW SAVE THE USER?
            check = determine_public_object_via_http(bucket, objs, readable_objects)
          end
          [check]
        end
        workers.flatten.map(&:join)

        _log_good "Found #{readable_objects.size} public object(s) that are readable."
        _log readable_objects # DEBUG
        readable_objects
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
