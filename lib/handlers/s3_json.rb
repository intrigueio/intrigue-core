require 'fog-aws'

module Intrigue
module Handler
  class S3Json < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "s3_json",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      puts "S3 JSON Handler called on #{result}: #{result.name}"
      access_key = _get_handler_config("access_key")
      secret_key = _get_handler_config("secret_key")
      bucket_name = _get_handler_config("bucket")
      region = _get_handler_config("region")

      connection = Fog::Storage::AWS.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key
      })

      # write to a tempfile first
      tempfile = Tempfile.new("export-#{rand(10000000)}.json")
      result.entities.paged_each do |e|
        tempfile.write("#{e.export_json}\n")
      end
      # rewind to beginning
      tempfile.rewind

      bucket = connection.directories.get(bucket_name)
      bucket.files.create (
        { :key => "#{prefix_name}#{result.name}.json",
          :body => tempfile.read
        }
      )

      tempfile.close
      tempfile.unlink

    end

  end
end
end
