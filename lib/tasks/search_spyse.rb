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
      :allowed_types => ["String", "Domain"],
      :example_entities => [{"type" => "String", "details" => {"name" => "jira"}}],
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
    headers = {"api_token" =>  api_key}

    # Returns aggregate information by subdomain word : total count of subdomains, list of IPs of subdomains and subdomain count on every IP,
    # list of countries and subdomain count from it, list of CIDRs /24, /16 and subdomain list on every CIDR.
    if entity_type == "String"
      url = "https://api.spyse.com/v1/domains-starts-with-aggregate?sdword=#{entity_name}"
      get_subdomains entity_name, api_key, headers, url

    # Returns aggregate information by domain: total count of subdomains, list of IPs of subdomains and subdomain count on every IP,
    # list of countries and subdomain count from it, list of CIDRs /24, /16 and subdomain list on every CIDR.
    elsif entity_type == "Domain"
      url = "https://api.spyse.com/v1//subdomains-aggregate?domain=#{entity_name}"
      get_subdomains entity_name, api_key, headers, url

    else
      _log_error "Unsupported entity type"
    end

  end #end run


  # Returns aggregate information by subdomain word and domain
  def get_subdomains entity_name, api_key, headers, url

    response = http_get_body(url,nil,headers)
    json = JSON.parse(response)

    #check if entries different to null
    if json["count"] != 0
      # Create subdomains
      json["cidr"]["cidr16"]["results"].each do |e|
        e["data"]["domains"].each do |s|
          _create_entity("DnsRecord", "name" => s)
        end
      end
     # Create subdomains
      json["cidr"]["cidr24"]["results"].each do |e|
        e["data"]["domains"].each do |s|
          _create_entity("DnsRecord", "name" => s)
        end
      end

      # Create list of related organizations
      json["data"]["as"]["results"].each do |e|
        _create_entity("Organization", "name" => e["entity"]["organization"])
      end

      # Create list of related countrys
      json["data"]["country"]["results"].each do |e|
        _create_entity("PhysicalLocation", "name" => e["entity"]["value"])
      end

      # Create list of related IPs
      json["data"]["ip"]["results"].each do |e|
        _create_entity("IpAddress", "name" => e["entity"]["value"])
      end
    end
  end #end subdomain

end
end
end
