module Intrigue
  module Entity
    class AzureStorageAccount < Intrigue::Core::Model::Entity
      # Azure Storage works in the following way:
      #### Storage Account
      ##### Container A
      ######## Blob 1
      ######## Blob 2
      ######## Blob 3
      ##### Container B
      ######## Blob 1
      ######## Blob 2
      ######## Blob 3

      def self.metadata
        {
          name: 'AzureStorageAccount',
          description: 'An Azure Storage Account',
          user_creatable: true,
          example: 'https://intrigue.blob.core.windows.net'
        }
      end

      def validate_entity
        name.match(/\w+\.blob\.core\.windows\.net/)
      end

      def detail_string
        "File count: #{details['contents'].count}" if details['contents']
      end

      def enrichment_tasks
        ['enrich/azure_storage_account']
      end

      def scoped?(_conditions = {})
        return scoped unless scoped.nil?
        return true if allow_list || project.allow_list_entity?(self)
        return false if deny_list || project.deny_list_entity?(self)

        true # otherwise just default to true
      end
    end
  end
end
