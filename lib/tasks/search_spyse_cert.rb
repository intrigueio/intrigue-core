module Intrigue
module Task
class SearchSpyseCert < BaseTask

  def self.metadata
    {
      :name => "search_spyse_cert",
      :pretty_name => "Search Spyse Cert",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Spyse API for discovring domains registered with the same certificate",
      :references => ["https://spyse.com/apidocs"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["SslCertificate"],
      :example_entities => [{"type" => "String", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","Organization","PhysicalLocation"]
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

    if entity_type == "SslCertificate"
      #search Ip for reputation, Open ports, related information
      search_domain_registered_with_same_cert entity_name,headers
    else
      _log_error "Unsupported entity type"
    end

  end #end run

  # search for domains registred with same certificate
  def search_domain_registered_with_same_cert(entity_name, headers)

    # Set the headers
    url = "https://api.spyse.com/v3/data/cert?limit=100&hash=#{entity_name}"

    # make the request
    response = http_get_body(url,nil,headers)
    json = JSON.parse(response)
    #puts json

    #create an issue if many domains founded registered with same Certificate
    json["data"]["items"].each do |result|
      if result["parsed"]["names"]
        _create_linked_issue("domains_registered_with_same_certificate",{
          references: ["https://spyse.com/"],
          source:"Spyse",
          details: result["parsed"]
        })
      end

      #create DnsRecord from domains registered with same certificate
      if result["parsed"]["names"]
        result["parsed"]["names"].each do |domain|
          _create_entity("DnsRecord", {"name" => domain })
        end
      end

      #create organizations related to the certificate
      if result["parsed"]["subject"]["organization"]
        result["parsed"]["subject"]["organization"].each do |organization|
          _create_entity("Organization", {"name" => organization })
        end
      end

    end
  end #end search_domain_registered_with_same_cert

end
end
end
