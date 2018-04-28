require 'fog-aws'

module Intrigue
module Handler
  class S3Json < Intrigue::Handler::Base

    def self.type
      "s3_json"
    end

    def process(result,prefix_name=nil)
      puts "S3 JSON Handler called on #{result}: #{result.name}"
      access_key = _get_handler_config("access_key")
      secret_key = _get_handler_config("secret_key")
      bucket_name = _get_handler_config("bucket")
      region = _get_handler_config("region")

      connection = Fog::Storage::AWS.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key
      })

      bucket = connection.directories.get(bucket_name)
      bucket.files.create (
        { :key => "#{prefix_name}#{result.name}.json",
          :body => result.export_json
        }
      )

    end

  end
end
end
