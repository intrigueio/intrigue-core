module Intrigue
  module Task
    class AzureStorageBlobsBrute < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'azure_storage_blobs_brute',
          pretty_name: 'Azure Storage Blobs Bruteforcer',
          authors: ['maxim'],
          description: 'This task will attempt to bruteforce the blobs which live within a container belonging to an Azure Storage Account. If the value of the <b>container</b> option is left default; the task will be run on all the containers that are stored in the entity\'s details.',
          references: ['https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction'],
          type: 'discovery',
          passive: true,
          allowed_types: ['AzureStorageAccount'],
          example_entities: [
            { 'type' => 'AzureStorageAccount', 'details' => { 'name' => 'intrigueio' } }
          ],
          allowed_options: [
            { name: 'container', regex: 'alpha_numeric_list', default: 'changeme-default.' },
            { name: 'additional_blobs_wordlist', regex: 'alpha_numeric_list', default: '' }
          ],
          created_types: ['AzureStorageAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        return unless azure_storage_account_exists?(@entity)
        return unless azure_storage_container_pub_access?(@entity)

        container_uris = create_container_uri_list
        return if container_uris.nil?

        container_uris.select! { |s| azure_storage_container_exists?(s) }
        _log_error 'None of the containers provided are public; thus aborting task.' if container_uris.empty?
        return if container_uris.empty?

        found_blobs = bruteforce_blobs(container_uris)
        _log "Bruteforce finished; found a total of #{found_blobs.size} blob(s) across #{container_uris.size} container(s)."
        return if found_blobs.empty?

        handle_results(found_blobs)
      end

      def create_container_uri_list
        containers = if _get_option('container') == 'changeme-default.'
                       # default container name not changed; will use containers from entity details
                       _get_entity_detail('containers').compact
                     else
                       [_get_option('container')]
                     end

        _log_error 'Entity has no containers associated with it / nor was one provided.' if containers.empty?
        containers.map { |c| "https://#{_get_entity_name}.blob.core.windows.net/#{c}" } unless containers.empty?
      end

      def prepare_blobs_list
        user_supplied_list = _get_option('additional_blobs_wordlist')
        default_list = File.read("#{$intrigue_basedir}/data/s3_common_objects.list").split("\n")
        default_list << user_supplied_list.delete(' ').split(',') unless user_supplied_list.empty?
        default_list.flatten.uniq
      end

      def create_brutelist(container_wordlist)
        blobs_wordlist = prepare_blobs_list
        container_wordlist.map do |c|
          blobs_wordlist.map do |w|
            "#{c}/#{w}"
          end
        end
      end

      def bruteforce_blobs(containers_list)
        listable_containers = containers_list.select { |c| container_listable?(c) }
        listable_blobs = listable_containers.map { |l| pillage_listable_container(l) }

        containers_list -= listable_containers # remove listable containers by diffing arrays
        return listable_blobs.flatten if containers_list.empty? # all the containers allowed public listing

        blob_bruteforce_list = create_brutelist(containers_list).flatten

        found_blob_uris = []
        _log 'Starting blob bruteforce.'
        workers = (0...20).map do
          check = brute_blob(blob_bruteforce_list, found_blob_uris)
          [check]
        end
        workers.flatten.map(&:join)

        (found_blob_uris + listable_blobs).flatten # combine arrays and flatten to return all URIs which were found
      end

      def brute_blob(input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while container_uri = input_q.shift
              r = http_request(:get, container_uri)
              output_q << container_uri if r.code == '200'
            end
          end
        end
        t
      end

      def container_listable?(uri)
        r = http_request(:get, "#{uri}/?comp=list")
        r.code == '200' && r.body.include?('EnumerationResults')
      end

      def pillage_listable_container(uri)
        r = http_request(:get, "#{uri}/?comp=list")
        xml_doc = Nokogiri::XML(r.body)
        xml_doc.remove_namespaces!
        xml_doc.xpath('//EnumerationResults//Blobs//Blob//Url').children.map(&:text)
      end

      def handle_results(results)
        # create issue per each container (not blob)
        # add URIS to azurestorageaccountentity 
        results.each do |r|
          add_blob_uri_to_entity_details(@entity, r)
          add_container_to_entity_details(@entity, extract_storage_container_from_string(r))
        end

        mapped_results = map_container_names_to_uri(results)
        mapped_results.each { |m| create_listable_container_issue(m) }

      end

      def map_container_names_to_uri(results)
        container_names_only = results.map { |r| extract_storage_container_from_string(r) }
        match_uri_with_containers = ->(c) { results.find_all { |r| extract_storage_container_from_string(r) == c } }

        container_names_only.uniq.map { |name| { name => match_uri_with_containers.call(name) } }
      end

      def create_listable_container_issue(m_hash)
        name, blobs = m_hash.first
        _create_linked_issue 'azure_storage_blob_public', {
          proof: "Azure Storage Container #{name} contains blobs which can be accessed by anonymous users.",
          source: "https://#{extract_storage_account_from_string(blobs.first)}.blob.core.windows.net/#{name}",
          uri: "https://#{extract_storage_account_from_string(blobs.first)}.blob.core.windows.net/#{name}",
          status: 'confirmed',
          details: {
            public_blobs: blobs
          }
        }
      end
    end
  end
end
