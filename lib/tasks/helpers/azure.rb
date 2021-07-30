module Intrigue
  module Task
    module Azure

      def extract_storage_account_from_string(str)
        str.scan(/(?:https:\/\/)?(\w+)\.blob\.core\.windows\.net/i).flatten.first
      end

      def extract_storage_container_from_string(str)
        str.scan(/(?:https:\/\/)?\w+\.blob\.windows\.core\.net\/([\w|\-]+)\/?/i).flatten.first
      end

      def add_container_to_entity_details(entity, container)
        containers = entity.get_detail('containers')
        containers << container
        entity.set_detail('containers', containers)
      end

    end
  end
end
