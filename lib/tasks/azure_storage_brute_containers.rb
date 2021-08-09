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
          allowed_types: ['AzureStorageAccount'],
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

        return unless public_access_allowed?

        results = bruteforce_containers(name)
        _log "Found #{results.size} container(s)!"
        return if results.empty?

        # add containers to entity details
        results.each { |r| add_container_to_entity_details(@entity, r) }

        # check if any of the containers allow for blobs to be listed
        listable_container_check(name, results)
      end

      def verify_storage_account_exists(name)
        _log 'Checking if Storage Account exists.'
        require_enrichment if _get_entity_detail('containers').nil? # force enrichment
        containers = _get_entity_detail('containers')

        # if containers nil meaning enrichment did not determine a valid storage account
        _log_error "The Storage Account #{name} does not exist" if containers.nil?
        containers
      end

      def public_access_allowed?
        _log 'Verifying whether Storage Account allows for public access.'
        access = _get_entity_detail('public_access_allowed')
        _log_error 'The top level Storage Account blocks public access; aborting.' unless access

        access
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

      # determine whether the container exists by issuing HTTP Requests
      def determine_container_exists(input_q, output_q, name)
        t = Thread.new do
          until input_q.empty?
            while container = input_q.shift
              r = http_request :get, "https://#{name}.blob.core.windows.net/#{container}/!!invalidblob!!"
              output_q << container if r.body.include?('The specified blob does not exist.')
            end
          end
        end
        t
      end

      def listable_container_check(account, valid_results)
        _log 'Checking whether any of the found containers allow for anonymous listing of blobs.'
        listable_check = ->(container_uri) { http_request(:get, container_uri).code == '200' }

        valid_results.select! { |r| listable_check.call("https://#{account}.blob.core.windows.net/#{r}/?comp=list") }
        return if valid_results.empty?

        _log_good "Found #{valid_results.size} container(s) that allow for anonymous listing of blobs."

        valid_results.each { |v| create_listable_container_issue("https://#{account}.blob.core.windows.net/#{v}/?comp=list") }
      end

      def create_listable_container_issue(proof_uri)
        _create_linked_issue('azure_blob_exposed_files', {
                               proof: 'This Azure Storage Container allows anonymous users to list blobs in its container.',
                               source: proof_uri,
                               status: 'confirmed'
                             })
      end
    end
  end
end
