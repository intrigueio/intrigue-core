module Intrigue
module Task
class SearchSpyseDomain < BaseTask

  def self.metadata
    {
      :name => "search_spyse_domain",
      :pretty_name => "Search Spyse Domain",
      :authors => ["Anas Ben Salah"],
      :description => "This task hits Spyse API for  domains registered with the same IP and related subdomains",
      :references => ["https://spyse.com/apidocs"],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [{"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
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

    if entity_type == "Domain"
      # Search Ip for domain hosted on the same IP
      search_domain_on_same_ip entity_name,headers

      # Search subdomain related to the domain
      search_subdomains entity_name,headers
    else
      _log_error "Unsupported entity type"
    end

  end #end

  # Search IP reputation and gathering data
  def search_domain_on_same_ip(entity_name, headers)

    # Set the URL for ip data
    url = "https://api.spyse.com/v3/data/domain/on_same_ip?limit=100&domain=#{entity_name}"

    # make the request
    response = http_get_body(url,nil,headers)
    json = JSON.parse(response)

    json["data"]["items"].each do |result|

      # Create Dnsrecords shared the same ip
      if result["name"]
        _create_entity("DnsRecord", "name" => result["name"], "extended_spyse" => result)
      end

      # Create SslCertificate
      if result["cert_summary"]["fingerprint_sha256"]
        _create_entity("SslCertificate", "name" => result["cert_summary"]["fingerprint_sha256"], "extended_spyse" => result["cert_summary"])
      end

      # Create related IpAddress, physical location and ISP organization
      if result["dns_records"]
        result["dns_records"]["A"].each do |ip_result|
          _create_entity("IpAddress", "name" => ip_result["ip"], "extended_spyse" => ip_result)
          _create_entity("PhysicalLocation", "name" => ip_result["country"])
          _create_entity("Organization", "name" => ip_result["org"])
        end
      end

    end
  end

  # Search for open ports
  def search_subdomains entity_name, headers

    # Set the URL for ip open ports
    url2 = "https://api.spyse.com/v3/data/domain/subdomain?limit=100&domain=#{entity_name}"

    # make the request
    response2 = http_get_body(url2,nil,headers)
    json2 = JSON.parse(response2)

    json2["data"]["items"].each do |result|

      # Create related subdomains
      _create_entity("DnsRecord", "name" => result["name"], "extended_spyse" => result)

      # Create SslCertificate
      if result["cert_summary"]["fingerprint_sha256"] != ""
        _create_entity("SslCertificate", "name" => result["cert_summary"]["fingerprint_sha256"], "extended_spyse" => result["cert_summary"])
      end
      # Create related IpAddress, physical location and ISP organization
      # if result["dns_records"]
      #   result["dns_records"]["A"].each do |ip_result|
      #     if ip_result["ip"] != ""
      #       _create_entity("IpAddress", "name" => ip_result["ip"], "extended_spyse" => ip_result)
      #     end
      #     if ip_result["country"] != ""
      #       _create_entity("PhysicalLocation", "name" => ip_result["country"])
      #     end
      #     if ip_result["org"] != ""
      #       _create_entity("Organization", "name" => ip_result["org"])
      #     end
      #   end
      #  end

    end
  end

end
end
end
