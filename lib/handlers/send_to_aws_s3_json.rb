require 'fog-aws'

module Intrigue
module Core
module Handler
  class SendToAwsS3Json < Intrigue::Core::Handler::Base

    def self.metadata
      {
        :name => "send_to_aws_s3_json",
        :pretty_name => "Send to AWS S3 (JSON)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      return "Unable to process" unless result.respond_to? "export_json"

      puts "AWS S3 JSON Handler called on #{result}: #{result.name}"
      access_key = _get_handler_config("aws_access_key")
      secret_key = _get_handler_config("aws_secret_key")
      bucket_name = _get_handler_config("aws_s3_bucket")
      region = _get_handler_config("aws_region")

      connection = Fog::Storage::AWS.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key
      })

      # write to a tempfile first
      tempfile = Tempfile.new("export-#{rand(10000000)}.json")
      result.entities.paged_each(rows_per_fetch: 500) do |e|
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
end