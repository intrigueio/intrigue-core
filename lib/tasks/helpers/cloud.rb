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

      # extracts the bucket_name from a URL
      # there can be different types of naming schemes - virtual hosted & path_style
      def extract_bucket_name_from_url(bucket_url)
        # Virtual Hosted Style
        # https://bucketname.s3.amazonaws.com
        # https://bucketname.s3-us-west-2.amazonaws.com/
        # bucketname.s3.amazonaws.com
        # bucketname.s3-region.amazonaws.com
        virtual_style_regex = /(?:https:\/\/)?(.+)\.s3\.amazonaws.com/ 

        ## Path Style -> being deprecated soon; adding in for legacy support
        # https://s3.amazonaws.com/bucketname
        # s3.amazonaws.com/bucketname
        path_style_regex = /(?:https:\/\/)?s3\.amazonaws\.com\/(.+)\/(?:.+)?/

        case bucket_url
        when virtual_style_regex
          bucket_name = bucket_url.scan(virtual_style_regex).last.first
        when path_style_regex
          bucket_name = bucket_url.scan(path_style_regex).last.first
        else
          _log_error 'Unable to extract bucket name from URL.'
          bucket_name = nil
        end

        bucket_name
      end

    end
  end
end
