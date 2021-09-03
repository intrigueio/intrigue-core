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
          
          if region = bucket_exists?(bucket_name)
            _set_entity_detail('bucket_name', bucket_name)
            _set_entity_detail('found_objects', []) unless _get_entity_detail('found_objects')
            _set_entity_detail('region', region)
            check_bucket_belongs_to_key(region, bucket_name)
          else
            _log_error 'Unable to determine region of bucket. Bucket most likely does not exist.'
            @entity.hidden = true
            @entity.save_changes
          end
        end

        def bucket_exists?(bucket_name)
          region = http_request(:get, "https://#{bucket_name}.s3.amazonaws.com").headers['x-amz-bucket-region']
          region
        end

        ## check if the AWS keys provided by the user own the bucket -> theres a better way of doing this
        def check_bucket_belongs_to_key(region, bucket_name)
          s3_client = initialize_s3_client(region, bucket_name)
          return if s3_client.nil?

          begin
            result = client.list_buckets['buckets'].collect(&:name).include? bucket
          rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled
            _log 'AWS Keys do not have permission to list the buckets belonging to the account; defaulting to false.'
          end

          return unless result

          _log 'Bucket belongs to API Key.' 
          _set_entity_detail 'source', 'configuration'
        end

      end
    end
  end
end
