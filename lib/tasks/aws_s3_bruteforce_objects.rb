module Intrigue
  module Task
    class AwsS3BruteforceObjects < BaseTask
      def self.metadata
        {
          name: 'aws_s3_bruteforce_objects',
          pretty_name: 'AWS S3 Bruteforce Objects',
          authors: ['maxim'],
          description: 'Bruteforces the S3 Bucket using a wordlist to find any readable objects. If valid AWS Keys are provided, the task will use authenticated techniques to attempt to read the object. <br><br><b>Please note:</b> if the bucket belongs to the provided AWS Keys, the task will default to using non-authenticated techniques as false positives will occur.<br><br>Task Options:<br><ul><li>objects_list - (default value: empty) - The list of comma-separated objects to use as the wordlist. If no objects are provided, a default wordlist of 100 common files will be used.</li><li>use_authentication - (default value: false) - Use authenticated techniques to attempt to list the bucket\'s objects.</ul>',
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
            { name: 'objects_list', regex: 'alpha_numeric_list', default: '' },
            { name: 'use_authentication', regex: 'boolean', default: true }
          ],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        region = s3_bucket_enriched? # check if bucket is enriched and if so a region will be returned if bucket exists
        return if region.nil?

        bucket_name = _get_entity_detail 'bucket_name'
        objects_list = parse_objects

        s3_client = initialize_s3_client(region, bucket_name)

        readable_objects = filter_readable_objects(s3_client, bucket_name, objects_list)
        return if readable_objects.empty?

        add_objects_to_s3_entity(@entity, readable_objects)
        create_issue(bucket_name, readable_objects)
      end

      # checks to see if use_authentication option has been set to true
      # if the bucket owns the key, we return false as false positives will occur
      def use_authentication?
        auth = _get_option('use_authentication')
        if auth && _get_entity_detail('belongs_to_api_key')
          _log 'Cannot use authentication if bucket belongs to API key as false positives will occur.'
          _log 'Defaulting to using unauthenticated techniques.'
          auth = false
        end
        auth
      end

      def parse_objects
        objects = _get_option('objects_list').delete(' ').split(',') # remove whitespaces between values and return array
        objects = File.read("#{$intrigue_basedir}/data/s3_common_objects.list").split("\n") if objects.empty?
        objects
      end

      # take in a list of objects and return the ones that are readable
      def filter_readable_objects(s3_client, bucket, objs)
        readable_objects = []
        use_auth_method = use_authentication?

        workers = (0...20).map do
          if s3_client && use_auth_method
            # we have valid aws keys and bucket does not belong to api key -> use api calls to get objects
            check = determine_public_object_via_api(s3_client, bucket, objs, readable_objects)
          else
            # WHAT IF THE API KEY HAS RESTRICTED PERMISSIONS? CAN WE SOMEHOW SAVE THE USER?
            # either invalid aws keys/key owned by buckets -> attempt to retrieve the object using http
            check = determine_public_object_via_http(bucket, objs, readable_objects)
          end
          [check]
        end
        workers.flatten.map(&:join)

        _log_good "Found #{readable_objects.size} public object(s) that are readable."
        readable_objects
      end

      # determine whether the object exists by issuing API calls
      def determine_public_object_via_api(client, bucket, input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while key = input_q.shift
              begin
                client.get_object({ bucket: bucket, key: key })
              rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AllAccessDisabled
                next
              end
              output_q << key
            end
          end
        end
        t
      end

      # determine whether the object exists by issuing HTTP Requests
      def determine_public_object_via_http(bucket, input_q, output_q)
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
