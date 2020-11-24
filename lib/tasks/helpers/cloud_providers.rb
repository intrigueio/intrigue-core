module Intrigue
module Task
module CloudProviders

  # this method checks the available attributes to determine if this is a cloud-hosted entity
  def determine_cloud_status(entity)

    # Start empty
    out = []

    # Check the relevant attributes on a per-entity basis 
    out = _get_cloud_status_dns_record(entity.name) if entity.kind_of? Intrigue::Entity::DnsRecord 
    out = _get_cloud_status_ip_address(entity.name) if entity.kind_of? Intrigue::Entity::IpAddress 
    out = _get_cloud_status_uri(entity.name) if entity.kind_of? Intrigue::Entity::Uri
    
  # return it   
  out 
  end

  private 

  def _cloud_classifier_lookup(ip_address)
    
    intrigueio_api_key = _get_task_config "intrigueio_api_key"
    unless intrigueio_api_key
      _log_error "Unable to check, verify you've entered a valid Intrigue.io API key!"
      return nil
    end

    begin 
      api_url = "https://app.intrigue.io/api/cloudclassifier/search/ip/#{ip_address}?key=#{intrigueio_api_key}"
      resp = http_get_body(api_url)

      json = JSON.parse(resp) if resp
      if json && json["name"]
        if json["name"] == json["service"]
          return "#{json["name"]}".downcase 
        else
          return "#{json["name"]}_#{json["service"]}".downcase 
        end
      end

    rescue JSON::ParserError => e 
      _log_error "Unable to parse API response"
    end
  
  nil
  end

  def _get_cloud_status_ip_address(ip_address)
    cloud_providers = []

    ###
    ### USE IP DATA
    ###
    lookup_result = _cloud_classifier_lookup(ip_address) 
    cloud_providers << lookup_result if lookup_result

    ###
    ### USE ASN / NET_NAME
    ###
    cloud_providers << "fastly" if _get_entity_detail("net_name") =~ /FASTLY/
    cloud_providers << "cloudflare" if _get_entity_detail("net_name") =~ /CLOUDFLARENET/
    cloud_providers << "amazon" if _get_entity_detail("net_name") =~ /AMAZON/

  cloud_providers
  end

  def _get_cloud_status_dns_record(dns_record)
    cloud_providers = []

    _get_entity_detail("resolutions").each do |resolution| 
      
      # only check ip addresses 
      res = resolution["response_data"] 
      next unless res.is_ip_address?
      
      lookup_result = _cloud_classifier_lookup(res) 
      cloud_providers << lookup_result if lookup_result
    end

    ###
    ### USE DNS
    ###
    cloud_providers << "amazon_ec2" if _get_entity_name =~ /amazonaws.com/
    cloud_providers << "google_gcp" if _get_entity_name =~ /bc.googleusercontent.com/
    cloud_providers << "microsoft_azure" if _get_entity_name =~ /cloudapp.azure.com/
    
  cloud_providers
  end

  def _get_cloud_status_uri(app)
    cloud_providers = []

    ###
    ### USE IP ADDRESS
    ###
    ip_address = _get_entity_detail("ip_address")
    lookup_result = _cloud_classifier_lookup(ip_address) if ip_address
    cloud_providers << lookup_result if lookup_result
    
    ###
    ### USE DNS
    ###
    cloud_providers << "amazon_ec2" if _get_entity_name =~ /amazonaws.com/
    cloud_providers << "google_gcp" if _get_entity_name =~ /bc.googleusercontent.com/
    cloud_providers << "microsoft_azure" if _get_entity_name =~ /cloudapp.azure.com/

    ###
    ### USE ASN / NET_NAME
    ###
    #cloud_providers << "fastly" if _get_entity_detail("net_name") == "FASTLY, US"
    cloud_providers << "amazon" if _get_entity_detail("net_name") =~ /AMAZON/


    ###
    ### FINGERPRINT
    ###
    _get_entity_detail("fingerprint").each do |fp|
      #cloud_providers << "#{fp["product"]}".downcase if fp["tags"] && fp["tags"].include?("Cloud")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"] && fp["tags"].include?("SaaS")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"] && fp["tags"].include?("IaaS")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"] && fp["tags"].include?("PaaS")
    end
    
  cloud_providers
  end

end
end
end