module Intrigue
  module Task
    class AzureStorageAccountBrute < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'azure_storage_account_brute',
          pretty_name: 'Azure Storage Account Bruteforcer',
          authors: ['maxim'],
          description: 'This task takes keywords and uses them to create permutations which are then bruteforced to confirm if an Azure Storage account with that name exists.<br><br>Task Options:<br><ul><li>additional_permutation_wordlist - (default value: empty) - Additional strings to use as a wordlist to generate permutations.</li><li>additional_keywords - (default value: false) - Additional keywords that can be used to generate bucket names with.</ul>',
          references: ['https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction'],
          type: 'discovery',
          passive: true,
          allowed_types: ['UniqueKeyword', 'Organization', 'String'],
          example_entities: [
            { 'type' => 'String', 'details' => { 'name' => 'intrigueio' } }
          ],
          allowed_options: [
            { name: 'additional_permutation_wordlist', regex: 'alpha_numeric_list', default: '' }
          ],
          created_types: ['AzureStorageAccount']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        # create permutations
        keyword = _get_entity_name
        permutations_list = create_permutation_wordlist(keyword)

        valid_accounts = bruteforce_storage_accounts(permutations_list)
        _log "Found #{valid_accounts.size} valid accounts."
        return if valid_accounts.empty?

        valid_accounts.each do |v| 
          create_entity(v)
          check_for_public_blob_access(v)
        end
      end

      def create_permutation_wordlist(keyword)
        perms = generate_permutations(keyword) # generate permutations
        perms << keyword
        perms.flatten
      end

      # generate permutations using the keywords provided along with the additional permutations wordlist
      def generate_permutations(key)
        _log "Generating permutations for keyword: #{key}"

        permutations = []
        additional_permutations = _get_option('additional_permutation_wordlist').delete(' ').split(',')

        words = %w[backup backups dev development eng engineering old prod qa stage staging test testing marketing web public private priv development env environment secret replica artifact]
        words << additional_permutations
        words.flatten!.uniq

        # generate different sets of permutations
        words.each do |word|
          permutations << "#{key}#{word}"
          permutations << "#{word}#{key}"
        end

        permutations
      end

      def bruteforce_storage_accounts(wordlist)
        accounts = []
        workers = (0...20).map do
          check = storage_account_exists?(wordlist, accounts)
          [check]
        end
        workers.flatten.map(&:join)
        accounts
      end

      # confirm the account exists via response code
      def storage_account_exists?(input_q, output_q)
        t = Thread.new do
          until input_q.empty?
            while account = input_q.shift
              status_code = http_request(:get, "https://#{account}.blob.core.windows.net").code
              output_q << account if status_code != '0'
            end
          end
        end
        t
      end

      def create_entity(account)
        _create_entity 'AzureStorageAccount', {
          'name' => "#{account}.blob.core.windows.net",
          'storage_account_name' => "#{account}.blob.core.windows.net",
          'uri' => "https://#{account}.blob.core.windows.net"
        }
      end

      def check_for_public_blob_access(account)
        return unless http_request(:get, "https://#{account}.blob.core.windows.net").code == '400'

        _create_linked_issue('azure_storage_account_public_acccess', {
                               proof: "This following storage account: #{account} allows public access to its containers.",
                               source: "https://#{account}.blob.core.windows.net",
                               status: 'confirmed'
                             })
      end
    end
  end
end
