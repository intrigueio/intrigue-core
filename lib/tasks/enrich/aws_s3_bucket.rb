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
          # set region
          region = http_request(:get, bucket_uri).headers['x-amz-bucket-region']
          _set_entity_detail 'region', region

          if _get_entity_detail 'authenticated' == true
            get_bucket_contents_authenticated(_get_entity_detail('bucket_name'), region)
          else
            get_bucket_contents_authenticated(_get_entity_detail('bucket_name'), region)
          end

        end

        def get_bucket_contents_authenticated(name, region)
          aws_access_key = _get_task_config('aws_access_key_id')
          aws_secret_key = _get_task_config('aws_secret_access_key')

          s3_resource = Aws::S3::Resource.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
          name = 'cali-bucket1337'
          require 'pry-remote'; binding.pry_remote
          public_read = []
          public_write = []

=begin
def check_read(obj)
  read = false
  obj.acl.grants.each do |grant|
    if grant.grantee.uri == "http://acs.amazonaws.com/groups/global/AllUsers"
      if grant.permission == "READ"
        # FULL_CONTROL
        # WRITE
        read = true
        end
      end
  end
  read
end
=end

          # check if object can be public
          # in order for object to be public its ACL needs to be set to public along with the top level bucket having some configuration allowing objects to be public
          # the easy way would be sending http requests per each object to see if you can retrieve response


          bucket = s3_resource.bucket(name)
          s3_client = bucket.client
          
        end

        def get_bucket_contents_unauthenticated() end
      end
    end
  end
end
