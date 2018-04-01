require 'fog-aws'

module Intrigue
module Handler
  class S3Csv < Intrigue::Handler::Base

    def self.type
      "s3_csv"
    end

    def process(result)
      puts "S3 CSV Handler called"
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
        { :key => "#{result.name}.csv",
          :body => result.export_csv
        }
      )

    end

  end
end
end
