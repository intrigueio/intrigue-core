require 'fog-aws'

module Intrigue
module Handler
  class SendToAwsS3Csv < Intrigue::Handler::Base

    def self.metadata
      {
        :name => "send_to_aws_s3_csv",
        :pretty_name => "Send to AWS S3 (CSV)",
        :type => "export"
      }
    end

    def perform(result_type, result_id, prefix_name=nil)
      result = eval(result_type).first(id: result_id)
      puts "S3 CSV Handler called on #{result}: #{result.name}"

      puts "AWS S3 CSV Handler called on #{result}: #{result.name}"
      access_key = _get_handler_config("aws_access_key")
      secret_key = _get_handler_config("aws_secret_key")
      bucket_name = _get_handler_config("aws_s3_bucket")
      region = _get_handler_config("aws_region")


      connection = Fog::Storage::AWS.new({
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key
      })

      # write to a tempfile first
      tempfile = Tempfile.new("export-#{rand(10000000)}.csv")
      result.entities.paged_each(rows_per_fetch: 500) do |e|
        tempfile.write("#{e.export_csv}\n")
      end
      # rewind to beginning
      tempfile.rewind

      bucket = connection.directories.get(bucket_name)
      bucket.files.create (
        { :key => "#{prefix_name}#{result.name}.csv",
          :body => tempfile.read
        }
      )

      tempfile.close
      tempfile.unlink

    end

  end
end
end
