module Intrigue
module Task
class SearchGreynoisie < BaseTask

  def self.metadata
  {
    :name => "threat/search_greynoisie",
    :pretty_name => "Threat Check - Search Greynoise",
    :authors => ["Anas Ben Salah"],
    :description => "This task hits the Greynoise API for IP context and information.",
    :references => ["https://docs.greynoise.io/"],
    :type => "discovery",
    :passive => true,
    :allowed_types => ["IpAddress"],
    :example_entities => [
      {"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}},
    ],
    :allowed_options => [],
    :created_types => []
  }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    api_key =_get_task_config("greynoise_api_key")

    headers = { "Accept" =>  "application/json" , "Key" => "#{api_key}" }

    unless api_key or username
      _log_error "unable to proceed, no API key for Greynoise provided!"
      return
    end
    
    if entity_type == "IpAddress"
      search_greynoise entity_name, headers
    else
      _log_error "Unsupported entity type"
    end

  end #end run


  #search greynoise for malicious IPs and context
  def search_greynoise entity_name,headers

    begin

      response = http_get_body("https://api.greynoise.io/v2/noise/context/#{entity_name}",nil, headers)
      result = JSON.parse(response)

      #check if the ip exist in greynoise database or not
      if result["seen"] == true

        if result["classification"] == "malicious"
          _create_linked_issue("suspicious_activity_detected",{
             status: "confirmed",
             classification: result["classification"],
             proof: result
          })
      end
    end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end

  end# end search_greynoise


end #end class
end
end
