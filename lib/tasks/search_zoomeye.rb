module Intrigue
module Task
class SearchZoomEye < BaseTask

  def self.metadata
    {
      :name => "search_zoomeye",
      :pretty_name => "Search Zoomeye",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Zoomeye API for  IP / Port lookup, DNS records and SslCertificate information",
      :references => ["https://www.zoomeye.org/doc"],
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
    #api_key = _get_task_config("spyse_api_key")
    # Set the headers
    data = { "username" =>  "jcran@intrigue.io" , "password" => "Rrs32m%5sX2%^4Gb" }
    url = "https://api.zoomeye.org/user/login"


    # make the request
    response = http_post(url,data,nil)
    json = JSON.parse(response)

    puts json 


  end #end run



end
end
end
