module Intrigue
  module Task
    class SearchThreatMiner < BaseTask
      def self.metadata
        {
          name: 'search_threatminer',
          pretty_name: 'Search ThreatMiner',
          authors: ['Xiao-Lei Xiao'],
          description: 'This task utilises a threat intelligence portal, ThreatMiner, to enable analysts to perform research into malware and network infrastructure.',
          references: ['https://www.threatminer.org/api.php'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [
            { 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }
          ],
          allowed_options: [],
          created_types: ['Domain', 'DnsRecord']
        }
      end

      ## Default method, subclasses must override this
      def run
        super
        entity_name = _get_entity_name
        search_threatminer 'domain', entity_name
      end

      def search_threatminer(indicator, query)
        response = http_get_body("https://api.threatminer.org/v2/#{indicator}.php?q=#{query}&rt=1", nil, {})

        json = JSON.parse(response)

        if json['results']
          json['results'].each do |result|
            nameservers = result['whois']['nameservers'].split("\n")
            nameservers.each do |ns|
              create_dns_entity_from_string ns
            end
          end
        end
      rescue JSON::ParserError => e
        _log_error "Unable to parse JSON: #{e}"
      end
    end
  end
end
