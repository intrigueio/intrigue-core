module Intrigue
module Task
class SearchShodan < BaseTask

  def self.metadata
    {
      :name => "search_shodan",
      :pretty_name => "Search Shodan",
      :authors => ["jcran"],
      :description => "Uses the SHODAN API to search for information",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [
        {"type" => "String", "details" => {"name" => "intrigue.io"}}
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
    response = @client.search_ip(search_term)

    # check to make sure we got a response.
    _log_error "ERROR: No response" unless response

    # Go through the results
    if response["data"]
      response["data"].each do |s|
        _log_good "Creating service on #{s["ip_str"]}: #{s["port"]}"
        _create_network_service_entity(@entity,s["port"],s["transport"] || "tcp", {
          :source => "shodan",
          :shodan_details => s
        })
      end
    end

  end

end
end
end
