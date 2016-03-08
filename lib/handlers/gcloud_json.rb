require "gcloud"
require "tempfile"

module Intrigue
module Handler
  class GcloudJson < Intrigue::Handler::Base

    def self.type
      "gcloud_json"
    end

    def process(result)

      ## so this is pretty funky but.. 
      # Gcloud uses Service Account credentials to connect to Google Cloud services. 
      # When running on Compute Engine the credentials will be discovered automatically. 
      # More info: https://github.com/GoogleCloudPlatform/gcloud-ruby
      
      bucket_name = _get_handler_config("bucket_name")
      object_name = "#{result.task_name}_on_#{result.base_entity.name}.json"

      gcloud = Gcloud.new
      storage = gcloud.storage
      bucket = storage.bucket bucket_name

      # create a tempfile to store the result
      temp_file = Tempfile.new("gcloud_json")
      temp_file.write JSON.pretty_generate(result.export_hash)

      bucket.create_file temp_file.path, object_name

      temp_file.close
      temp_file.unlink

      temp_file = nil
      bucket = nil
      storage = nil
      gcloud = nil

    end

  end
end
end
