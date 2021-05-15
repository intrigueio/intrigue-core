module Intrigue
  module Task
    class SearchRiddler < BaseTask
      include Intrigue::Task::Web

      def self.metadata
        {
          name: 'search_riddlerio',
          pretty_name: 'Search Riddler.io',
          authors: ['maxim'],
          description: 'Retrieves additional subdomains usingthe Riddler.io API.',
          references: ['https://riddler.io'],
          type: 'discovery',
          passive: true,
          allowed_types: ['Domain'],
          example_entities: [{ 'type' => 'Domain', 'details' => { 'name' => 'intrigue.io' } }],
          allowed_options: [],
          created_types: ['DnsRecord', 'Domain']
        }
      end

      def run
        super
        domain = _get_entity_name

        _log "Getting results for #{domain} from Riddler.io"
        results = query_riddler(domain) || [] # catch nil

        _log_error "No subdomains were retrieved for #{domain}." if results.empty?
        return if results.empty?

        # subdomains were retrieved -> create dns_entities from them
        _log_good "Retrieved #{results.count} results."
        results.each do |r|
          create_dns_entity_from_string r
        end
      end

      # Helper function to query thte api
      def query_riddler(query)
        url = "https://riddler.io/search/exportcsv?q=pld:#{query}"
        response = http_get_body(url)

        # response will be returned as an empty string if the site cannot be reached 
        # parse out the CSV response
        fqdns = CSV.parse(response, 'col_sep': ',').map do |row|
          row[4] unless row[4] == 'FQDN' # remove fqdn column from results
        rescue CSV::MalformedCSVError
          _log_error 'Unable to parse CSV returned by response.'
          return nil
        end

        fqdns.compact.uniq

      end
    end
  end
end
