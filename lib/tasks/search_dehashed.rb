module Intrigue
module Task
class SearchDehashed < BaseTask

  def self.metadata
  {
    :name => "search_dehashed",
    :pretty_name => "Search DeHashed",
    :authors => ["Anas Ben Salah"],
    :description => "This task hits the Dehashed API for leaked accounts. ",
    :references => ["https://www.dehashed.com/docs"],
    :type => "discovery",
    :passive => true,
    :allowed_types => ["EmailAddress","IpAddress","Domain","String"],
    :example_entities => [
      {"type" => "EmailAddress", "details" => {"name" => "x@x.com"}},
      {"type" => "IpAddress", "details" => {"name" => "192.0.78.13"}},
      {"type" => "Domain", "details" => {"name" => "intrigue.io"}},
      {"type" => "String", "details" => {"name" => "username, password, password_hash, name"}}
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

    username =_get_task_config("dehashed_username")
    api_key =_get_task_config("dehashed_api_key")

    headers = {
      "Accept" =>  "application/json" ,
      "Authorization" => "Basic #{Base64.encode64("#{username}:#{api_key}").strip}" }

    unless api_key or username
      _log_error "unable to proceed, no API key for Dehashed provided"
      return
    end

    #search for EmailAddress if it a partof  in a data breach
    if entity_type == "EmailAddress"
      search_dehashed entity_name, headers
    elsif entity_type == "IpAddress"     #search by IP Address for related leaks
      search_dehashed entity_name, headers
    elsif entity_type == "String"  # search by username,password,hashed password names for related leaks
      search_dehashed entity_name, headers
    elsif entity_type == "Domain"
      search_dehashed entity_name, headers
    else
      _log_error "Unsupported entity type"
    end

  end #end run


  #search dehashed for EmailAddress if it a partof  in a data breach
  def search_dehashed entity_name,headers

    #check if entries different to null
    begin

      response = http_get_body("https://api.dehashed.com/search?query=#{entity_name}",nil,headers)
      json = JSON.parse(response)

      _log "Got JSON: #{json}"

      if json["entries"]
        json["entries"].each do |result|

        _create_linked_issue("leaked_account",{
          proof: result,
          type:"leaked_account",
          detailed_description: "Email:#{result["email"]}\n username: #{result["username"]}\n password: *******#{result["password"][-4...-1]}\n
          # Hashed Password:#{result["hashed_password"]}\n IP Address: #{result["ip_address"]}\n phone:#{result["phone"]} Source #{result["obtained_from"]}",
          source: result["obtained_from"],
          details: result
        })

      end
    end

    rescue JSON::ParserError => e
      _log_error "Unable to parse JSON: #{e}"
    end

  end# end search_dehashed


end #end class
end
end
