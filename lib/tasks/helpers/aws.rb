module Intrigue
  module Task
    module Aws
      # aws helpers?

      def initialize_s3_client(aws_access_key, aws_secret_key)
        region = _get_entity_detail('region')
        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        api_key_valid?(client)
      end

      def s3_api_key_valid?(client)
        client.get_object({ bucket: 'test', key: "#{SecureRandom.uuid}.txt" })
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        _log_error 'AWS Access Keys are not valid; will ignore keys and use unauthenticated techniques for enrichment.'
        _set_entity_detail 'belongs_to_api_key', false # auto set to false since we are unable to check
        nil
      rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied
        # keys are valid, we are expecting this error
        client
      end

    end
  end
end
