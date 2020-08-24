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

    client = Client::Search::Shodan::ApiClient.new(api_key)
    response = client.search_ip(search_term)

    # check to make sure we got a response.
    unless response && response["data"]
      _log_error "ERROR: #{response["error"]}"
      return false
    end

    # Go through the results
    _set_entity_detail("extended_shodan",response["data"])

    response["data"].each do |resp|

      # create an entity for each service (this handles known aliases), save the raw data
      response["data"].each do |s|
        _log_good "Creating service on #{s["ip_str"]}: #{s["port"]}"
        _create_network_service_entity(@entity, s["port"], s["transport"] || "tcp", {
          "shodan_timestamp" => resp["timestamp"],
          "extended_shodan" => resp } )
      end

      # Create all hostnames
      resp["hostnames"].each do |h|
        _log_good "Creating dns record: #{h}"
        #_create_entity "DnsRecord", "name" => "#{h}"
        create_dns_entity_from_string h
      end

      # search Ip if it a honeypot
      response_honeyscore = client.search_ip(search_term)

      # check to make sure we got a response.
      unless response
        _log_error "ERROR: could not get response from Shodan.io"
        return false
      end

      if response_honeyscore == "1.0"
        _create_linked_issue("honeypot_detected",{
         source:"shodan.io" ,
         references: ["https://honeyscore.shodan.io/"] })
      else
        return false
      end 

      # Create all domains
      #resp["domains"].each do |d|
      #  _log_good "Creating domain: #{d}"
      #  check_and_create_unscoped_domain d
      #end

      # Create the organization if we have it
      #if resp["org"]
      #  _log_good "Creating organization: #{resp["org"]}"
      #  _create_entity "Organization", "name" => "#{resp["org"]}"
      #end

    end

  end

end
end
end
