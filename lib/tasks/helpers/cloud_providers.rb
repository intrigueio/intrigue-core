require 'pry'

module Intrigue
module Task
module CloudProviders

  # this method checks the available attributes to determine if this is a cloud-hosted entity
  def determine_cloud_status(entity)

    # Start empty
    out = []

    # Check the relevant attributes on a per-entity basis 
    out = _get_cloud_status_dns_record(entity) if entity.kind_of? Intrigue::Entity::DnsRecord 
    out = _get_cloud_status_ip_address(entity) if entity.kind_of? Intrigue::Entity::IpAddress 
    out = _get_cloud_status_uri(entity) if entity.kind_of? Intrigue::Entity::Uri
    
  # return it   
  out 
  end

  private 

  def _get_cloud_status_ip_address(ip_address)
    cloud_providers = []

    ###
    ### USE IP DATA
    ###


    ###
    ### USE ASN / NET_NAME
    ###
    cloud_providers << "fastly" if _get_entity_detail("net_name") == "FASTLY, US"

  cloud_providers
  end

  def _get_cloud_status_dns_record(dns_record)
    cloud_providers = []

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
    ### USE DNS
    ###
    cloud_providers << "amazon_ec2" if _get_entity_name =~ /amazonaws.com/
    cloud_providers << "google_gcp" if _get_entity_name =~ /bc.googleusercontent.com/
    cloud_providers << "microsoft_azure" if _get_entity_name =~ /cloudapp.azure.com/

    ###
    ### USE ASN / NET_NAME
    ###
    cloud_providers << "fastly" if _get_entity_detail("net_name") == "FASTLY, US"
    cloud_providers << "amazon" if _get_entity_detail("net_name") == "AMAZON"

    ###
    ### FINGERPRINT
    ###
    _get_entity_detail("fingerprint").each do |fp|
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"].include?("Cloud")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"].include?("SaaS")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"].include?("IaaS")
      cloud_providers << "#{fp["product"]}".downcase if fp["tags"].include?("PaaS")
    end
    
  cloud_providers
  end

end
end
end