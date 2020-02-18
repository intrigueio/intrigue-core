module Intrigue
module Task
class SearchApility < BaseTask

  def self.metadata
    {
      :name => "search_apility",
      :pretty_name => "Search Apility",
      :authors => ["Anas Ben Salah"],
      :description => "This task search Apility API for IP address and domain reputation",
      :references => ["https://api.apility.net/v2.0/ip/"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress","Domain"],
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}},
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  # Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    api_key =_get_task_config("apility_api_key")

    headers = {
      "Accept" =>  "application/json" ,
      "X-Auth-Token" => api_key
    }

    if entity_type == "IpAddress"
      search_apility_by_ip entity_name, headers
    elsif entity_type == "Domain"
      search_apility_by_domain entity_name, headers
    else
      _log_error "Unsupported entity type"
    end

  end


  # search apility by IP
  def search_apility_by_ip entity_name, headers

    # Get the Api response
    response = http_get_body("https://api.apility.net/badip/#{entity_name}",nil, headers)
    if response == "Resource not found"
      return
    end
    json = JSON.parse(response)

    # Check if the result is not empty


    # Check if response different to nil
    if json["response"]
      json["response"].each do |e|
        source = e
        description = "apility.io is a blacklist aggregator"

        # Create an issue if the ip is flaged in one of the blacklists
        _create_linked_issue("suspicious_ip", {
          status: "confirmed",
          additional_description: description,
          source: source,
          proof: "This IP was founded related to malicious activities in #{source}",
          references: []
        })

       # Also store it on the entity
        blocked_list = @entity.get_detail("detected_malicious") || []
        @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))

      end
    end
  end # end search_apility_by_ip


  # search apility by domain
  def search_apility_by_domain entity_name, headers

    # Get the Api response
    response = http_get_body("https://api.apility.net/baddomain/#{entity_name}",nil, headers)
    json = JSON.parse(response)


    # Check if response different to nil
    if json["response"]
      # Check if the domain is listed in a blacklist
      if json["response"]["domain"]["blacklist"]
        #create an issue per source
        json["response"]["domain"]["blacklist"].each do |e|
          source = e
          description = "apility.io is a blacklist aggregator"
          # Create an issue if the ip is flaged in one of the blacklists
          _create_linked_issue("suspicious_domain", {
            status: "confirmed",
            additional_description: description,
            source: source,
            proof: "This domain was founded flaged in #{source} blacklist",
          })
         # Also store it on the entity
          blocked_list = @entity.get_detail("detected_malicious") || []
          @entity.set_detail("detected_malicious", blocked_list.concat([{source: source}]))
        end
      end

      # check if Nameserver is not empty
      if json["response"]["domain"]["ns"]
        json["response"]["domain"]["ns"].each do |n|
          # create Nameserver entity
          _create_entity("Nameserver", "name" => n)
        end
      end

      # Create an IP entity
      _create_entity("IpAddress", "name" => json["response"]["ip"]["address"])


    end
  end # end search_apility_by_domain

end #end class
end
end
