module Intrigue
  module Task
    class AzureStorageContainerBrute < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'azure_storage_container_bruteforce',
          pretty_name: 'Azure Storage Container Bruteforcer',
          authors: ['maxim'],
          description: 'This task accepts an Azure Storage Account and bruteforces the names of common containers attempting to find containers that allow anonymous read access.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['AzureStorageAccount', 'Uri'],
          example_entities: [
            { 'type' => 'AzureStorageAccount', 'details' => { 'name' => 'intrigueio' } }
          ],
          allowed_options: [
            { name: 'additional_container_wordlist', regex: 'alpha_numeric_list', default: '' }
          ],
          created_types: []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        name = _get_entity_name
        return unless verify_storage_account_exists(name)

        if public_access_blocked?(name)
          _log_error 'The top level Storage Account blocks public access; meaning containers are not public.'
          return
        end

        results = bruteforce_containers(name)
        _log "Found #{results.size} containers!"
        return if results.empty?

        _log 'Adding results to entity details.'
        results.each { |r| add_container_to_entity_details(@entity, r) }
      end

      def verify_storage_account_exists(name)
        require_enrichment if _get_entity_detail('containers').nil? # force enrichment
        containers = _get_entity_detail('containers')

        # if containers nil meaning enrichment did not determine a valid storage account
        _log_error "The Storage Account #{name} does not exist" if containers.nil?
        containers
      end

      # maybe lets do this in the enrichment process?
      def public_access_blocked?(account)
        rbody = http_get_body("https://#{account}.blob.core.windows.net")
        rbody.include? 'Public access is not permitted on this Storage Account.'
      end

      def bruteforce_containers(account)
        containers_input = prepare_wordlist

        found_containers = []

        _log 'Starting container bruteforce.'
        workers = (0...20).map do
          check = determine_container_exists(containers_input, found_containers, account)
          [check]
        end
        workers.flatten.map(&:join)

        found_containers
      end

      def prepare_wordlist
        user_supplied_list = _get_option('additional_container_wordlist')
        default_list = File.read("#{$intrigue_basedir}/data/azure_containers.list").split("\n")
        default_list << user_supplied_list.delete(' ').split(',') unless user_supplied_list.empty?
        default_list.flatten.uniq 
      end

      # determine whether the object exists by issuing HTTP Requests
      def determine_container_exists(input_q, output_q, name)
        t = Thread.new do
          until input_q.empty?
            while container = input_q.shift
              r = http_request :get, "https://#{name}.blob.core.windows.net/#{container}/?comp=list"
              output_q << container if r.code == '200'
            end
          end
        end
        t
      end

    end
  end
end
