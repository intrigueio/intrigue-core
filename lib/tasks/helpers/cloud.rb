module Intrigue
  module Task
    module Cloud
      # cloud helpers?

      def initialize_s3_client(aws_access_key, aws_secret_key, region)
        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        client
      end

      def aws_key_valid?(client, bucket_name)
        client.get_object({ bucket: bucket_name, key: "#{SecureRandom.uuid}.txt" })
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        _log 'AWS Access Keys are invalid; ignoring keys.'
        nil
      rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied
        # keys are valid, we are expecting this error
        _set_entity_detail 'aws_keys_valid', true
        client
      end

    end
  end
end
