module Intrigue
  module Task
    module Enrich
      class AwsS3Bucket < Intrigue::Task::BaseTask
        
        def self.metadata
          {
            name: 'enrich/aws_s3_bucket',
            pretty_name: 'Enrich AwsS3Bucket',
            authors: ['jcran', 'maxim'],
            description: 'Fills in details for an AwsS3Bucket.',
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
          # TODO bug fix: when entity is created from task; name detail is not stored
          bucket_name = _get_entity_detail('name') || _get_entity_detail('bucket_name')
          
          # check if the bucket actually exists. If not, this will hide the entity.
          return unless bucket_exists?(bucket_name)

          # check if bucket is owned by aws keys in configuration
          region = _get_entity_detail('region')
          s3_client = initialize_s3_client(region, bucket_name)
          bucket_belongs_to_api_key?(s3_client, bucket_name) if s3_client
        end
 
        ## confirm the bucket exists by extracting the region from the response headers
        def bucket_exists?(bucket_name)
          exists = true
          region = http_request(:get, "https://#{bucket_name}.s3.amazonaws.com").headers['x-amz-bucket-region']

          if region.nil?
            @entity.hidden = true # bucket is invalid; hide the entity
            _log_error 'Unable to determine region of bucket. Bucket most likely does not exist.'
            exists = false
          else
            _log "Bucket lives in the #{region} region."
            _set_entity_detail 'region', region
            _set_entity_detail 'bucket_name', bucket_name 
          end

          exists
        end


        ## check if the AWS keys provided by the user own the bucket -> theres a better way of doing this
        def bucket_belongs_to_api_key?(client, bucket)
          result = false

          begin
            result = client.list_buckets['buckets'].collect(&:name).include? bucket
          rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled
            _log 'AWS Keys do not have permission to list the buckets belonging to the account; defaulting to false.'
          end

          if result
            _log 'Bucket belongs to API Key.' 
            _set_entity_detail 'source', 'configuration'
          end
        end

      end
    end
  end
end
