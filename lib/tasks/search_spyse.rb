module Intrigue
module Task
class SearchSpyse < BaseTask

  def self.metadata
    {
      :name => "search_spyse",
      :pretty_name => "Search Spyse",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Spyse API for subdomains, IP / Port lookup, DNS records and SslCertificate information",
      :references => ["https://spyse.com/apidocs"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress","String", "Domain"],
      :example_entities => [{"type" => "String", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","IpAddress","Organization","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Make sure the key is set
    api_key = _get_task_config("spyse_api_key")
    # Set the headers
    headers = { "Accept" =>  "application/json" , "Authorization" => "Bearer #{api_key}" }

    if entity_type == "IpAddress"
      #search Ip for reputation, Open ports, related information
<<<<<<< HEAD
      search_ip_reputation entity_name,headers
=======
      #search_ip_reputation entity_name,headers
      search_open_ports entity_name,headers
>>>>>>> 7bcacce1aa058b21884acf92c4b05619be062cbe
    else
      _log_error "Unsupported entity type"
    end

  end #end

<<<<<<< HEAD
  #Lists open ports on IP
  # def search_ip_port(entity_name, headers)
  #
  #   # Set the headers
  #   url = "https://api.spyse.com/v2/data/ip/port?limit=100&ip=#{entity_name}"
  #
  #   # make the request
  #   response = http_get_body(url,nil,headers)
  #   json = JSON.parse(response)
  #   #puts json
  #   json["data"]["items"].each do |result|
  #       puts "#{entity_name}: #{result["port"]}"
  #     if result["service"] == ""
  #
  #     #_create_entity("IpAddress", {"name" => entity_name, "open_port" => result["port"] , "service" => result["service"]})
  #       _log_good "Creating service on #{entity_name}: #{result["port"]}"
  #       _create_network_service_entity(@entity, result["port"])
  #     else
  #       _log_good "Creating service on #{entity_name}: #{result["port"]}"
  #       _create_network_service_entity(@entity, result["port"],result["service"])
  #     end
  #   end
  # end

  #search IP
  def search_ip_reputation(entity_name, headers)

    # Set the headers
    url = "https://api.spyse.com/v2/data/ip?limit=100&ip=#{entity_name}"

    # make the request
    response = http_get_body(url,nil,headers)
    json = JSON.parse(response)
    #puts json
    json["data"]["items"].each do |result|
      # #create physical location
      # if result["maxmind_geo"]["country"]
        # puts result["maxmind_geo"]["country"]
         #_create_entity("PhysicalLocation", "name" => result["maxmind_geo"]["country"])
      # end
      # # Create list of related organizations
      # if result["maxmind_isp"]["org"]
         #puts result["maxmind_isp"]["org"]
         #_create_entity("Organization", "name" => result["entity"]["organization"])
      # end

      if result["score"] < 100
        _create_linked_issue("suspicious_activity_detected",{
          severity: result["score"],
          references: ["https://spyse.com/"],
          source:"Spyse",
          details: result
        })
      end
    end
    # Search for open ports
    url2 = "https://api.spyse.com/v2/data/ip/port?limit=100&ip=#{entity_name}"

    # make the request
    response2 = http_get_body(url2,nil,headers)
    json2 = JSON.parse(response2)
    #puts json
    json2["data"]["items"].each do |result|
        puts "#{entity_name}:#{result["port"]}"
      #_create_entity("IpAddress", {"name" => entity_name, "open_port" => result["port"] , "service" => result["service"]})
        _log_good "Creating service on #{entity_name}: #{result["port"]}"
        _create_network_service_entity(@entity, result["port"])
    end
  end

  

=======
  # Search IP reputation and gathering data
  def search_ip_reputation(entity_name, headers)

    # Set the URL for ip data
    url = "https://api.spyse.com/v2/data/ip?limit=100&ip=#{entity_name}"

    begin 
      # make the request
      response = http_get_body(url,nil,headers)
      json = JSON.parse(response)

      json["data"]["items"].each do |result|

        # Create an issue if result score indicates a score related to the threat
        if result["score"] < 100
          _create_linked_issue("suspicious_activity_detected",{
            severity: result["score"],
            references: ["https://spyse.com/"],
            source: "Spyse",
            details: result
          })
        end

      end
    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end
  end

  # Search for open ports
  def search_open_ports entity_name, headers

    # Set the URL for ip open ports
    url = "https://api.spyse.com/v3/data/ip/port?limit=100&ip=#{entity_name}"

    begin 
      # make the request
      response = http_get_body(url,nil,headers)
      json = JSON.parse(response)

      json["data"]["items"].each do |result|
        _log_good "Creating service on #{entity_name}: #{result["port"]}"
        _create_network_service_entity(@entity, result["port"],protocol="tcp",generic_details={"extended_spyse" => result})
      end
    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end
    
  end
>>>>>>> 7bcacce1aa058b21884acf92c4b05619be062cbe

end
end
end
