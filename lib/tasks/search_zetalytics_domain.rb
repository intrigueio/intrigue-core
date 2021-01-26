module Intrigue
module Task
class SearchZetalyticsByDomain < BaseTask

  def self.metadata
    {
      :name => "search_zetalytics_by_domain",
      :pretty_name => "Search Zetalytics By Domain",
      :authors => ["Anas Ben Salah"],
      :description => "This task search Zetalytics for a given domain name and returns related entities such as DnsRecords, related IPs and EmailAddress.",
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

    begin
      entity_name = _get_entity_name
      entity_type = _get_entity_type_string

      # make sure values are set
      unless entity_name
        # Something went wrong with the lookup?
        _log "Unable to get entity value"
        return
      end

      # Make sure the key is set
      api_key = _get_task_config("zetalytics_api_key")

      unless api_key
        _log_error "No credentials?"
        return
      end

      if entity_type =="Domain"
        search_zetalytics_by_domain(api_key, entity_name)
      # log error if Unsupported entity type
      else
        _log_error "Unsupported entity type"
      end #end if
    end
  end #end run

  # search zetalytics for a specific domain name
  def search_zetalytics_by_domain(api_key, domain)
    _log "Searching zetalytics by domain"
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
      result_subdomain = zetalytics.search_subdomains domain
      create_entities result_subdomain

      # Search for domains sharing a known registered email address or SOA email from passive
      #result_email_address = zetalytics.search_email_address domain
      #create_entities result_email_address

      # Search for domains sharing a registration email address domain
      #result_email_domain = zetalytics.search_email_domain domain
      #create_entities result_email_domain

    rescue RestClient::Forbidden => e
      _log_error "Error when querying zetalytics (forbidden)"
    end
  end


  def create_entities (result)
    return unless result != nil

    # these are possible keys that can be found in the api response.
    # the value of these keys can be a dns record, ip or email address
    # the regex will match the correct entity type and create the entity
    keys_to_check = ["qname", "hname", "ip", "value", "d", "addr"]
    # Mapping all the related entities to the domain name
    result["results"].each do |e|
      keys_to_check.each do |k|
        if e.key?(k)
          if e[k] =~ ipv4_regex or e[k] =~ ipv6_regex
            _create_entity("IpAddress", "name" => e[k])
          elsif e[k] =~ dns_regex
            _create_entity("DnsRecord", "name" => e[k], "zetalytics_details" => e)
          elsif e[k] =~ /[a-zA-Z0-9\.\_\%\+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
            _create_entity("EmailAddress", "name" => e[k])
          end
        end
      end
    end
  end

end
end
end
