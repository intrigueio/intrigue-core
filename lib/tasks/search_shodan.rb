module Intrigue
  module Task
    class SearchShodan < BaseTask
      def self.metadata
        {
          name: 'search_shodan',
          pretty_name: 'Search Shodan',
          authors: ['jcran'],
          description: 'Uses the SHODAN API to search for information',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['IpAddress', 'NetBlock'],
          example_entities: [
            { 'type' => 'IpAddres', 'details' => { 'name' => 'intrigue.io' } }
          ],
          allowed_options: [],
          created_types: ['DnsRecord', 'IpAddress', 'NetworkService', 'Organization', 'PhysicalLocation']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        # Get the API Key
        api_key = _get_task_config 'shodan_api_key'
        search_term = _get_entity_name
        entity_type = _get_entity_type_string

        client = Client::Search::Shodan::ApiClient.new(api_key)
        response = entity_type == 'IpAddress' ? client.search_ip(search_term) : client.search_netblock(search_term)

        # check to make sure we got a response.
        unless response && response['data']
          _log_error "ERROR: #{response}"
          return false
        end

        # Go through the results
        _set_entity_detail('extended_shodan', response['data'])

        response['data'].each do |s|
          next if s['port'].nil?

          _log_good "Creating service on #{s['ip_str']}: #{s['port']}"

          e = @entity # no need to enrich if original entity was an IP Address
          e = _create_entity 'IpAddress', { 'name' => s['ip_str'] } if entity_type == 'NetBlock'

          _create_network_service_entity(e, s['port'], s['transport'] || 'tcp', {
                                           'shodan_timestamp' => s['timestamp'],
                                           'extended_shodan' => s
                                         })

          s['hostnames']&.each { |h| create_dns_entity_from_string(h) }
          # check_if_honeypot(s['ip_str'])
        end
      end

      # honeypot api endpoint has been deprecated
      # come back & fix later
      # if response_honeyscore == "1.0"
      #   _create_linked_issue("honeypot_detected",{
      #   proof: response,
      #   source:"shodan.io" ,
      #   references: ["https://honeyscore.shodan.io/"] })
      # else
      #   return false
      # end

      # Create all domains
      # resp["domains"].each do |d|
      #  _log_good "Creating domain: #{d}"
      #  check_and_create_unscoped_domain d
      # end

      # Create the organization if we have it
      # if resp["org"]
      #  _log_good "Creating organization: #{resp["org"]}"
      #  _create_entity "Organization", "name" => "#{resp["org"]}"
      # end
    end
  end
end
