require 'aws-sdk'

module Intrigue
module Handler
  class S3Json < Intrigue::Handler::Base

    def self.type
      "s3_json"
    end

    def process(result)

      access_key = _get_handler_config("access_key")
      secret_key = _get_handler_config("secret_key")
      bucket_name = _get_handler_config("bucket")
      region = _get_handler_config("region")

      Aws.config.update({
        region: region,
        credentials: Aws::Credentials.new(access_key,secret_key)
      })

      s3 = Aws::S3::Resource.new
      obj = s3.bucket(bucket_name).object("#{result.task_name}_on_#{result.base_entity.name}.json")
      obj.put(body: JSON.pretty_generate(result.export_hash))

    end

  end
end
end
