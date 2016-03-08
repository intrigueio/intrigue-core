require "gcloud"
require "tempfile"

module Intrigue
module Handler
  class GcloudJson < Intrigue::Handler::Base

    def self.type
      "gcloud_json"
    end

    def process(result)

      # Grab configuration
      bucket_name = _get_handler_config("bucket_name")
      project_id = _get_handler_config("project_id")
      path_to_keyfile = _get_handler_config("path_to_keyfile")
      object_name = "#{result.task_name}_on_#{result.base_entity.name}.json"

      # More info: https://github.com/GoogleCloudPlatform/gcloud-ruby
      gcloud = Gcloud.new project_id, path_to_keyfile
      storage = gcloud.storage
      bucket = storage.bucket bucket_name

      # create a tempfile to store the result
      temp_file = Tempfile.new("gcloud_json")
      temp_file.write JSON.pretty_generate(result.export_hash)
      temp_file.close

      # Write the file to the bucket 
      bucket.create_file temp_file.path, object_name

      # Clean up
      temp_file.unlink
      temp_file = nil
      bucket = nil
      storage = nil
      gcloud = nil

    end

  end
end
end
