module Intrigue
  module Task
    module Enrich
      class AzureStorageAccount < Intrigue::Task::BaseTask
        def self.metadata
          {
            name: 'enrich/azure_storage_account',
            pretty_name: 'Enrich AzureStorageAccount',
            authors: ['maxim'],
            description: 'Fills in details for an AzureStorageAccount.',
            references: [],
            type: 'enrichment',
            passive: true,
            allowed_types: ['AzureStorageAccount'],
            example_entities: [
              { 'type' => 'AzureStorageAccount', 'details' => { 'name' => 'storageaccount' } }
            ],
            allowed_options: [],
            created_types: []
          }
        end

        ## Default method, subclasses must override this
        def run
          name = _get_entity_detail('name') || _get_entity_detail('storage_account_name')
          if storage_account_exists?(name)
            # list of empty containers which other task will populate unless another task already populated
            _set_entity_detail('containers', []) unless _get_entity_detail('containers')
            _set_entity_detail('public_access_allowed', public_access_allowed?(name))
          else
            _log_error 'Storage account does not exist.'
            @entity.hidden = true # bucket is invalid; hide the entity
            @entity.save_changes
          end
        end

        ## confirm the bucket exists by extracting the region from the response headers
        def storage_account_exists?(storage_account)
          _log 'Verifying whether Storage Account exists.'
          r = http_request(:get, "https://#{storage_account}.blob.core.windows.net", nil, {}, nil, true, 10)
          # if the storage account does not exist, its a non existent host therefore 0 status code
          r.code != '0'
        end

        def public_access_allowed?(storage_account)
          _log 'Verifying whether Storage Account allows for public access.'
          r = http_request(:get, "https://#{storage_account}.blob.core.windows.net", nil, {}, nil, true, 10)
          r.code == '400' && r.body.include?('InvalidQueryParameterValue')
        end

      end
    end
  end
end
