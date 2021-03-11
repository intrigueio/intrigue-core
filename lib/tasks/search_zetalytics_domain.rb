module Intrigue
module Task
class SearchZetalyticsDomain < BaseTask

  def self.metadata
    {
      :name => "search_zetalytics_domain",
      :pretty_name => "Search Zetalytics By Domain",
      :authors => ["Anas Ben Salah"],
      :description => "This task searches Zetalytics for a given domain and returns 
        Domain, DnsRecord and EmailAddress results found via Passive DNS ",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["Domain"],
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [],
      :created_types => ["DnsRecord", "IpAddress", "EmailAddress"]
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    domain_name = _get_entity_name

    # first check... if this is a wildcard domain, we cannot continue, 
    # results will be generally untrustworthy. 
    # todo... in the future, make a list and we can check against it 
    if wcs = gather_wildcard_ips(domain_name).count > 1 
      _log_error "Cowardly refusing to pull data on a wildcard domains"
      _log_error "wildcards: #{wcs}"
      return 
    end

    # Make sure the key is set
    api_key = _get_task_config("zetalytics_api_key")

    # search it 
    result = search_zetalytics_by_domain(api_key, domain_name)
    
    # create our entities 
    create_entities(result) if result

  end #end run

  # search zetalytics for a specific domain name
  def search_zetalytics_by_domain(api_key, domain)
    _log "Searching zetalytics by domain: #{domain}"
    begin
      # Initialize Zetalytics API with api key
      zetalytics = Zetalytics::Api.new(api_key)

      # search zetalytics by hostname for related data
      #result_hostname = zetalytics.search_by_hostname domain
      #create_entities result_hostname

      # Search passive dns by domain for AAAA (IPv6) records
      #result_ipv6 = zetalytics.search_domain_for_ipv6_records domain
      #create_entities result_ipv6

      # Search passive dns by domain for CNAME records
      #result_cname = zetalytics.search_domain2cname domain
      #create_entities result_cname

      # Search passive dns by domain for A (IPv4) records
      #result_ipv4 = zetalytics.search_domain2ip domain
      #create_entities result_ipv4

      # Search zonefile changes by domain for DNAME record.
      #result_dname = zetalytics.search_domain_dname_records domain
      #create_entities result_dname

      # Search name server glue (IP) records by domain name.
      #result_glue = zetalytics.search_domain2nsglue domain
      #create_entities result_glue

      # Search passive dns by domain for a list of subdomains from any record type.
      result = zetalytics.search_subdomains domain

      # Search for domains sharing a known registered email address or SOA email from passive
      #result_email_address = zetalytics.search_email_address domain
      #create_entities result_email_address

      # Search for domains sharing a registration email address domain
      #result_email_domain = zetalytics.search_email_domain domain
      #create_entities result_email_domain

    rescue RestClient::Forbidden => e
      _log_error "Error when querying zetalytics (forbidden)"
    end

  result
  end


  def create_entities(result)
    # these are possible keys that can be found in the api response.
    # the value of these keys can be a dns record, ip or email address
    # the regex will match the correct entity type and create the entity
    keys_to_check = ["qname", "hname", "ip", "value", "d", "addr"]

    # Mapping all the related entities to the domain name
    result["results"].each do |e|
      keys_to_check.each do |k|
        if e.key?(k)
          if e[k] =~ /[a-zA-Z0-9\.\_\%\+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
            _create_entity("EmailAddress", "name" => e[k])
          else 
            create_dns_entity_from_string(e[k], nil, false, e) if resolve_name e[k]
          end
        end
      end
    end

  end

end
end
end
