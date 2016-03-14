module Intrigue
module Handler
  class S3Json < Intrigue::Handler::Base

    def self.type
      "s3_json"
    end

    def process(result)

      require 'fog'

      access_key = _get_handler_config("access_key")
      secret_key = _get_handler_config("secret_key")
      bucket_name = _get_handler_config("bucket")
      region = _get_handler_config("region")
      object_name = "#{_export_file_name(result)}.json"

      connection = Fog::Storage::AWS.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key
      })

      bucket = connection.directories.get(bucket_name)
      bucket.files.create (
        { :key => object_name,
          :body => JSON.pretty_generate(result.export_hash)
        }
      )

    end

  end
end
end
