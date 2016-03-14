
module Intrigue
module Handler
  class GcloudJson < Intrigue::Handler::Base

    def self.type
      "gcloud_json"
    end

    def process(result)
      require "fog"

      # Grab configuration
      bucket_name = _get_handler_config("bucket_name")
      developer_email = _get_handler_config("developer_email")
      project_id = _get_handler_config("project_id")
      path_to_keyfile = _get_handler_config("path_to_keyfile")
      object_name = "#{_export_file_name(result)}.json"

      connection = Fog::Storage::Google.new({
        :google_client_email => developer_email,
        :google_project => project_id,
        :google_json_key_location => path_to_keyfile,
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
