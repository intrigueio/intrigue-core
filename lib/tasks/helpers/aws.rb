module Intrigue
  module Task
    module AwsHelper # conflicts with official AWS module so this is named AWS Helper
    
      # return an s3 client
      def initialize_s3_client(region='us-east-1', bucket_name)
        # use us-east-1 as default bucket unless one is specified
        begin
          aws_access_key = _get_task_config('aws_access_key_id')
          aws_secret_key = _get_task_config('aws_secret_access_key')
        rescue MissingTaskConfigurationError
          # keys are not set in config; return nil so unauth techniques can be used for some tasks
          return nil
        end
        client = Aws::S3::Client.new(region: region, access_key_id: aws_access_key, secret_access_key: aws_secret_key)
        client = _s3_aws_key_valid?(client, bucket_name)
        client
      end

      # checks if the bucket has been enriched and if so returns the region (as its required to initalize the s3 client)
      # if bucket does not exist; we end the task abruptly as theres no point in working with a non-existent bucket
      def s3_bucket_enriched?
        require_enrichment if _get_entity_detail('region').nil?
        region = _get_entity_detail('region')
        _log_error 'Bucket does not have a region meaning it does not exist; exiting task.' if region.nil?
        region
      end

      # return whether the s3 client is valid
      # in the future abstract this to work with different types of AWS clients
      def _s3_aws_key_valid?(client, bucket_name)
        client.get_object({ bucket: bucket_name, key: "#{SecureRandom.uuid}.txt" })
      rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
        _log 'AWS Access Keys are invalid; ignoring keys.'
        nil
      rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled
        # keys are valid, we are expecting this error
        _set_entity_detail 'aws_keys_valid', true
        client
      end

      def extract_bucket_name_from_string(str)
        virtual_style_regex = /(?:https:\/\/)?([a-z0-9\-\.]+)\.s3(?:-|.+)?\.amazonaws\.com/i
        path_style_regex = /(?:https:\/\/)?s3\.amazonaws\.com\/([\w\.\-]+)/i
        concat_regex = Regexp.union(virtual_style_regex, path_style_regex)

        str.scan(concat_regex).flatten.compact.last

      end

    end
  end
end
