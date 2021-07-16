module Intrigue
  module Task
    class SearchWayBack < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'search_wayback_machine',
          pretty_name: 'Search Wayback Machine',
          authors: ['maxim', 'jcran', 'mhmdiaa'],
          description: 'Retrieves subdomains using the Wayback Machine API.',
          references: ['http://web.archive.org/', 'https://gist.github.com/mhmdiaa/adf6bff70142e5091792841d4b372050'],
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

        _log "Retrieving results for #{domain} from Wayback Machine"
        json = query_wayback(domain) || [] # catch nil

        _log_error "No entities were retrieved for #{domain}." if json.empty?
        return if json.empty?

        hosts = json.flatten.map do |record|
          URI.parse(record).host
        rescue URI::InvalidURIError
          log_error "Unable to parse entity: #{record}. Skipping."
          next
        end

        _log_good "Retrieved #{hosts.compact.uniq.count} entities."
        hosts.uniq.compact.each { |h| create_dns_entity_from_string h }

      end

      # Helper function to query the api
      def query_wayback(query)
        url = "http://web.archive.org/cdx/search/cdx?url=*.#{query}&output=json&fl=original&collapse=urlkey"

        begin
          response = http_get_body(url)
          json = JSON.parse(response) # if nothing is parsed it returns an empty array
        rescue JSON::ParserError
          _log_error 'Unable to parse JSON response.'
        end

        json

      end
    end
  end
end
