module Intrigue
module Task
class SearchZoomEye < BaseTask

  def self.metadata
    {
      :name => "search_zoomeye",
      :pretty_name => "Search Zoomeye",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Zoomeye API for Port lookup, NetworkService, Nameserver , Related Organization and Physical location information",
      :references => ["https://www.zoomeye.org/doc"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["IpAddress", "Domain"],
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "1.1.1.1"}}],
      :allowed_options => [],
      :created_types => ["NetworkService","Nameserver","Organization","PhysicalLocation"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    entity_name = _get_entity_name
    entity_type = _get_entity_type_string

    # Make sure the key is set
    username_key = _get_task_config("zoomeye_username_key")
    password_key = _get_task_config("zoomeye_password_key")

    url = URI("https://api.zoomeye.org/user/login")
    body = {"username":"#{username_key}","password":"#{password_key}"}

    response = http_request(:post,url.to_s,nil,headers={"content-type" => "application/json"},body.to_s)
    puts response
    json = JSON.parse(response.read_body)
    token = json["access_token"]

    headers = { "Accept" =>  "application/json" , "Authorization" => "JWT #{token}" }

    if entity_type == "IpAddress"
      search_zoomeye_ip entity_name, headers
    elsif entity_type == "Domain"
      search_zoomeye_domain entity_name, headers
    else
      _log_error "Unsupported entity type"
    end

  end #end run

  # Search zoomeye by ip
  def search_zoomeye_ip entity_name, headers

    # Set the URL for ip open ports
    url ="https://api.zoomeye.org/host/search?query=ip:#{entity_name}"

    begin
      # make the request
      response = http_get_body(url,nil,headers)
      json = JSON.parse(response)

      json["matches"].each do |result|
        # Search for open ports
        _log_good "Creating service on #{entity_name}: #{result["portinfo"]["port"]}"
        _create_network_service_entity(@entity, result["portinfo"]["port"],protocol="tcp",generic_details={"extended_zoomeye" => result["portinfo"]})
        # Create Physical Location
        _create_entity("PhysicalLocation", "name" => result["portinfo"]["country"]["names"]["en"])
        # Create related Organization (ISP)
        _create_entity("Organization", "name" => ip_result["portinfo"]["isp"])

      end

    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end

  end

  # Search zoomeye by hostname
  def search_zoomeye_domain entity_name, headers

    # Set the URL for ip open ports
    url ="https://api.zoomeye.org/host/search?query=hostname:#{entity_name}"

    begin
      # make the request
      response = http_get_body(url,nil,headers)
      json = JSON.parse(response)

      json["matches"].each do |result|
        # Search for open ports
        _log_good "Creating service on #{entity_name}: #{result["portinfo"]["port"]}"
        _create_network_service_entity(@entity, result["portinfo"]["port"],protocol="tcp",generic_details={"extended_zoomeye" => result["portinfo"]})
        # Create Physical Location
        _create_entity("PhysicalLocation", "name" => result["portinfo"]["country"]["names"]["en"])
        # Create related Organization (ISP)
        _create_entity("Organization", "name" => ip_result["portinfo"]["isp"])
        # Create Nameserver
        _create_entity("Nameserver", {"name" => result["rdns"]})

      end

    rescue JSON::ParserError => e
      _log_error "Error while parsing #{e}"
    end

  end




end
end
end
