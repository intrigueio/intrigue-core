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
