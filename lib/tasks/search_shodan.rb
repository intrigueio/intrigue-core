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
    api_key = _get_task_config "shodan_api_key"
    search_term = _get_entity_name

    unless api_key
      _log_error "No api_key?"
      return
    end

    @client = Client::Search::Shodan::ApiClient.new(api_key)
    response = @client.search_ip(search_term)

    # check to make sure we got a response.
    unless response
      _log_error "ERROR: No response. Do you have API Access / Credits?"
      return false
    end

    # Go through the results
    if response["data"]

      # save raw data on the IP
      _set_entity_detail("raw_shodan",response["data"])

      # create an entity for each service (this handles known aliases)
      response["data"].each do |s|
        _log_good "Creating service on #{s["ip_str"]}: #{s["port"]}"
        _create_network_service_entity(@entity, s["port"], s["transport"] || "tcp")
      end

    end

  end

end
end
end
