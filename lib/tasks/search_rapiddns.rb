module Intrigue
  module Task
    class SearchRapidDNS < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'search_rapiddns',
          pretty_name: 'Search RapidDNS',
          authors: ['maxim'],
          description: 'Retrieves subdomains via RapidDNS.',
          references: ['https://rapiddns.io'],
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

        _log "Retrieving results for #{domain} from RapidDNS."

        # large sites take longer than 10 seconds (default timeout of http_get_body) to return
        response = http_request(:get, "https://rapiddns.io/subdomain/#{domain}?full=1#result", nil, {}, nil, true, 45).body
        subdomains = parse_response(response)

        _log "Retrieved a total of #{subdomains.size} results."
        subdomains.each { |s| create_dns_entity_from_string(s) } unless subdomains.empty?
      end

      def parse_response(http_response)
        doc = Nokogiri::HTML(http_response)
        parsed_subdomains = doc.xpath('//*[@id="table"]').search('tr').map { |tr| tr.content.split("\n")[2] }
        parsed_subdomains.drop(1).uniq # the first element will always be 'Domain' whether results returned or not
      end

    end
  end
end
