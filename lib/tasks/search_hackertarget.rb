module Intrigue
  module Task
    class SearchHackerTarget < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'search_hackertarget',
          pretty_name: 'Search HackerTarget',
          authors: ['maxim'],
          description: 'Retrieves subdomains using the HackerTarget API.',
          references: ['https://api.hackertarget.com'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [{ 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: ['Domain', 'DnsRecord']
        }
      end

      def run
        super
        domain = _get_entity_name

        _log "Retrieving results for #{domain} from HackerTarget"
        response = http_get_body("https://api.hackertarget.com/hostsearch/?q=#{domain}")

        if response.empty? || response =~ /error check your search parameter/i
          _log_error "No entities were retrieved for #{domain}."
          return nil
        end

        # parse out subdomains
        subdomains = response.split("\n").map { |item| item.split(',')[0] }

        _log_good "Retrieved #{subdomains.count} entities."
        # create entities
        subdomains.each { |s| create_dns_entity_from_string s }
      end

    end
  end
end
