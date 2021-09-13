module Intrigue
module Task
class SearchIBMXForce < BaseTask

  def self.metadata
    {
      :name => "threat/search_ibm_x_force",
      :pretty_name => "Threat Check - Search IBM X Force",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits IBM API for IP information such as DNS records, History and threat feeds",
      :references => ["https://exchange.xforce.ibmcloud.com/api/doc/?"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "String", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["IpAddress","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Make sure the key is set
    api_key =_get_task_config("ibm_x_force_api_key")
    password =_get_task_config("ibm_x_force_password")

    # Set the headers
    headers = {
      "Accept" =>  "application/json" ,
      "Authorization" => "Basic #{Base64.encode64("#{api_key}:#{password}").strip}"
    }

    if entity_type == "IpAddress"
      #search Ip for reputation and related information
      search_ip_reputation(entity_name, headers)
    else
      _log_error "Unsupported entity type"
    end

  end #end

  # Get IP Reputation
  def search_ip_reputation(entity_name, headers)

    # Set the URL for ip data
    url = "https://api.xforce.ibmcloud.com:443/ipr/history/#{entity_name}"

    # make the request
    response = http_get_body(url,nil,headers)
    json = JSON.parse(response)

    if json["error"] == "Not authorized."

      _log_error "Not authorized. Please check your API credentials."

      return

    end

    json["history"].each do |result|

      # Create physical location
      if result["score"] > 5
        if result["geo"]["country"]
             _create_entity("PhysicalLocation", "name" => result["geo"]["country"])
        end
      end

      # Create issue with meduim severity if IP score between 5 and 8
      if result["score"] > 5 && result["score"] < 8
        _create_linked_issue("suspicious_activity_detected",{
          severity: 3,
          references: ["https://exchange.xforce.ibmcloud.com/ip/#{entity_name}"],
          source:"IBM X Force #{result["score"]}",
          proof: result
        })
      end

      # Create issue with meduim severity if IP score over 8
      if result["score"] >= 8
        _create_linked_issue("suspicious_activity_detected",{
          severity: 2,
          references: ["https://exchange.xforce.ibmcloud.com/ip/#{entity_name}"],
          source:"IBM X Force #{result["score"]}",
          proof: result
        })
      end
    end

  end

end
end
end
