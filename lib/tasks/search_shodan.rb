module Intrigue
class SearchShodanTask < BaseTask

  def self.metadata
    {
      :name => "search_shodan",
      :pretty_name => "Search Shodan",
      :authors => ["jcran"],
      :description => "Uses the SHODAN API to search for information",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","DnsServer","IpAddress","NetworkService","String"],
      :example_entities => [
        {"type" => "String", "attributes" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord","IpAddress","NetworkService","Organization","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # Get the API Key
    api_key = _get_global_config "shodan_api_key"
    search_term = _get_entity_name

    unless api_key
      _log_error "No api_key?"
      return
    end

    @client = Client::Search::Shodan::ApiClient.new(api_key)
    response = @client.search(search_term)

    # check to make sure we got a response.
    raise "ERROR: No response" unless response

    # Check to make sure we got results
    if response["matches"]

      _log "Found #{response["matches"].count} matches"

      # Go through the results
      response["matches"].each do |r|

        _log "* SHODAN Record *"

        #updated_at = DateTime.new(r["updated"])
        updated_at = DateTime.now

        #
        # Create a host record
        #
        if r["ip"]
          # TODO - assumes ipv4, which isn't always true. Make sure to check for ipv6.
          ip_address = IPAddr.new(r['ip'],Socket::AF_INET)
          _log "IP: #{r["ip"]}"
          host = _create_entity("IpAddress",{
            "name" => "#{ip_address}",
            "age" => "#{updated_at}",
          })
        end

        #
        # Create a network_service
        #
        _log "Port: #{r["port"]}"

        port = _create_entity("NetworkService",{
          "name" => "#{host.attributes[:name]}:#{r["port"]}/tcp",
          "proto" => "tcp",
          "port_num" => r["port"],
          "fingerprint" => r["data"],
          "age" => "#{updated_at}"
        }) if r["port"] && host

        #
        # Create an organization
        #
        _log "Org: #{r["org"]}"
        org = _create_entity("Organization",{
          "name" => "#{r["org"]}",
          "age" => "#{updated_at}"
        }) if r["org"]

        #
        # Create a PhysicalLocation
        #
        _log "Location: #{r["postal_code"]}"
        location = _create_entity("PhysicalLocation",{
          "name" => "#{r["latitude"]} / #{r["longitude"]}",
          "zip" => "#{r["postal_code"]}",
          "state" => "#{r["region_name"]}",
          "country" => "#{r["country_name"]}",
          "latitude" => "#{r["latitude"]}",
          "longitude" => "#{r["longitude"]}",
          "age" => "#{updated_at}"
        }) if r["country_name"]


        _log "Port: #{r["port"]}"
        _log "Port Data: #{r["data"]}"
        _log "Country: #{r["country_name"]}"
        _log "Country Code: #{r["country_code"]}"
        _log "Region Name: #{r["region_name"]}"
        _log "Area Code: #{r["area_code"]}"
        _log "DMA Code: #{r["dma_code"]}"
        _log "Postal Code: #{r["postal_code"]}"
        _log "Org: #{r["org"]}"

      end
    end
  end

end
end
