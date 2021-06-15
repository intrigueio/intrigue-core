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
          bucket_name = _get_entity_detail 'name'

          return unless check_if_bucket_exists(bucket_name)

          s3_client = initialize_s3_client bucket_name
          bucket_belongs_to_api_key?(s3_client, bucket_name) if s3_client
        end

        ## confirm the bucket exists by extracting the region from the response headers
        def check_if_bucket_exists(bucket_name)
          exists = true
          region = http_request(:get, "https://#{bucket_name}.s3.amazonaws.com").headers['x-amz-bucket-region']
          if region.nil?
            @entity.hidden = true # bucket is invalid; hide the entity
            _log_error 'Unable to determine region of bucket. Bucket most likely does not exist.'
            exists = false
          else
            _log "Bucket lives in the #{region} region."
            _set_entity_detail 'region', region
          end
          exists
        end

        ## create the s3_client
        def initialize_s3_client(bucket)
          return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')

          region = _get_entity_detail 'region'
          aws_access_key = _get_task_config('aws_access_key_id')
          aws_secret_key = _get_task_config('aws_secret_access_key')

          client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
          api_key_valid?(client, bucket)
        end
        
        ## check if AWS keys are in fact valid
        def api_key_valid?(client, bucket)
          client.get_object({ bucket: bucket, key: "#{SecureRandom.uuid}.txt" })
        rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
          _log_error 'AWS Access Keys are not valid; will ignore keys and use unauthenticated techniques for enrichment.'
          _set_entity_detail 'belongs_to_api_key', false # auto set to false since we are unable to check
          nil
        rescue Aws::S3::Errors::NoSuchKey
          # keys are valid, we are expecting this error
          client
        end

        ## check if the AWS keys provided by the user own the bucket
        def bucket_belongs_to_api_key?(client, bucket)
          result = false

          begin
            result = client.list_buckets['buckets'].collect(&:name).include? bucket
          rescue Aws::S3::Errors::AccessDenied
            _log 'AWS Keys do not have permission to list the buckets belonging to the account; defaulting to false.'
          end

          _log 'Bucket belongs to API Key.' if result
          _set_entity_detail 'belongs_to_api_key', result
        end

      end
    end
  end
end
