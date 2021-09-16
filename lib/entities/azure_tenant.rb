module Intrigue
  module Entity
    class AzureTenant < Intrigue::Core::Model::Entity
      def self.metadata
        {
          name: 'AzureTenant',
          description: 'Azure Tenant ID',
          sensitive: true
        }
      end

      def validate_entity
        sensitive_details['azure_tenant_id']
      end

      def scoped?
        return true if scoped
        return true if allow_list || project.allow_list_entity?(self)
        return false if deny_list || project.deny_list_entity?(self)

        true # otherwise just default to true
      end
    end
  end
end
