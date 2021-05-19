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
              { 'type' => 'AwsS3Bucket', 'details' => { 'name' => 'https://s3.amazonaws.com/bucket' } }
            ],
            allowed_options: [
              { name: 'large_file_size', regex: 'integer', default: 25 }
            ],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          bucket_uri = _get_entity_detail 'name' || _get_entity_name
          # set region; if bucket is valid the URI below will work
          region = http_request(:get, bucket_uri).headers['x-amz-bucket-region']

          if region.nil?
            _log_error 'Unable to determine region of bucket. Bucket most likely does not exist.'
            return
          end

          _set_entity_detail 'region', region

          if _get_entity_detail 'authenticated' == true
            get_bucket_contents_authenticated _get_entity_detail('bucket_name'), region
          else
            get_bucket_contents_unauthenticated 
          end
        end

        # LEFT TO DO:
        # - Check policy if whole bucket is writeable
        # - Check policy if whole bucket is readable
        def get_bucket_contents_authenticated(name, region)
          aws_access_key = _get_task_config('aws_access_key_id')
          aws_secret_key = _get_task_config('aws_secret_access_key')

          s3_client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)

          public_read = []
          public_write = []

          bucket_keys = s3_client.list_objects_v2(bucket: name).contents.collect(&:key)

          workers = (0...20).map do
            acl_checks = check_object_perms(s3_client, name, bucket_keys, public_read, public_write)
            [acl_checks]
          end
          workers.flatten.map(&:join)

          create_issues public_read, public_write unless public_read.empty? || public_write.empty? # this will be changed if the whole bucket is readable/writeable
        end

        def get_bucket_contents_unauthenticated
          # this is where we bruteforce the actual file names?
        end

        ### helper methods for tasks above

        def check_object_perms(client, bucket, keys_q, read_collection, write_collection)
          t = Thread.new do
            until keys_q.empty?
              while key = keys_q.shift
                obj_acl = client.get_object_acl(bucket: bucket, key: key)
                obj_acl.grants.each do |grant|
                  if grant.grantee.uri == 'http://acs.amazonaws.com/groups/global/AllUsers'
                    if grant.permission == 'READ'
                      read_collection << key
                    elsif ['FULL_CONTROL', 'WRITE'].include? grant.permission
                      write_collection << key
                    end
                  end
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
