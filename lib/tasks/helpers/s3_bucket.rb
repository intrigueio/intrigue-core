module Intrigue
  module Task
    module S3Bucket
      # aws helpers?

      def initialize_s3_client_helper(bucket, region = 'us-east-1')
        return unless _get_task_config('aws_access_key_id') && _get_task_config('aws_secret_access_key')
        
        region = region
        aws_access_key = _get_task_config('aws_access_key_id')
        aws_secret_key = _get_task_config('aws_secret_access_key')

        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        api_key_valid?(client, bucket)
      end

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
    end
  end
end
