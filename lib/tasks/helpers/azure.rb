module Intrigue
  module Task
    module Azure

      def extract_storage_account_from_string(str)
        str.scan(/(?:https:\/\/)?(\w+)\.blob\.core\.windows\.net/i).flatten.first
      end

      def extract_storage_container_from_string(str)
        str.scan(/(?:https:\/\/)?\w+\.blob\.core\.windows\.net\/([\w|\-]+)\/?/i).flatten.first
      end

      def add_container_to_entity_details(entity, container)
        containers = entity.get_detail('containers')
        return if containers.include? container

        containers << container
        entity.set_detail('containers', containers)
      end

      def add_blob_uri_to_entity_details(entity, blob)
        blobs = entity.get_detail('blobs')
        return if blobs.include? blob

        blobs << blob
        entity.set_detail('blobs', blobs)
      end

      def azure_storage_container_pub_access?(entity)
        _log 'Verifying whether Storage Account allows for public access.'
        access = entity.get_detail('public_access_allowed')
        _log_error 'The top level Storage Account blocks public access; aborting.' unless access

        access
      end

      def azure_storage_account_exists?(entity)
        _log 'Checking if Storage Account exists.'
        require_enrichment if entity.get_detail('containers').nil? # force enrichment
        containers = entity.get_detail('containers')

        # if containers nil meaning enrichment did not determine a valid storage account
        _log_error "The Storage Account #{entity.name} does not exist" if containers.nil?
        containers.nil? ? false : true
      end
  
      # verify whether the container has container or blob access levels
      # if container access level is set to private then no point in performing any actions
      # the same response is returned if a container doesnt exist and if its private
      def azure_storage_container_exists?(container_uri)
        r = http_request :get, "#{container_uri}/!!invalidblob!!"
        r.body.include?('The specified blob does not exist.')
      end

      def create_azure_storage_entity(name)
        _create_entity 'AzureStorageAccount', {
          'name' => name,
          'storage_account_name' => name,
          'uri' => "https://#{name}.blob.core.windows.net"
        }
      end

    end
  end
end
