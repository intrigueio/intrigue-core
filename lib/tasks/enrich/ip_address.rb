module Intrigue
module Task
module Enrich
class IpAddress < Intrigue::Task::BaseTask

  def self.metadata
    {
      :name => "enrich/ip_address",
      :pretty_name => "Enrich IpAddress",
      :authors => ["jcran"],
      :description => "Fills in details for an IpAddress",
      :references => [],
      :allowed_types => ["IpAddress"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run

    lookup_name = _get_entity_name.strip

    # Set IP version
    if @entity.name =~ /:/
      _set_entity_detail("version",6)
    else
      _set_entity_detail("version",4)
    end

    ########################
    ## Handle ANY Records ##
    ########################
    results = resolve(lookup_name)

    _log "Got results: #{results}"

    ####
    ### Create aliased entities
    ####
    results.each do |result|
      _log "Creating entity for... #{result["name"]}"

      next unless result["name"]

      if "#{result["name"]}".is_ip_address?
        _create_entity("IpAddress", { "name" => result["name"] }, @entity)
      else
        _create_entity("DnsRecord", { "name" => result["name"] }, @entity)
        
        # create a domain for this entity
        check_and_create_unscoped_domain(result["name"])

        # check dev/staging server
        # if we're external, let's see if this matches 
        # a known dev or staging server pattern
        if !match_rfc1918_address?(lookup_name)
          dev_server_name_patterns.each do |p|
            if "#{result["name"]}".split(".").first =~ p
              _exposed_server_identified(p,result["name"])
            end
          end
        end

      end
    end

    # get ASN
    # look up the details in team cymru's whois
    _log "Using Team Cymru's Whois Service..."
    cymru = cymru_ip_whois_lookup(lookup_name)
    _set_entity_detail("asn", cymru[:net_asn])
    _set_entity_detail("net_block", cymru[:net_block])
    _set_entity_detail("net_country_code", cymru[:net_country_code])
    _set_entity_detail("net_rir", cymru[:net_rir])
    _set_entity_detail("net_allocation_date",cymru[:net_allocation_date])
    _set_entity_detail("net_name",cymru[:net_name])
    _create_entity "AutonomousSystem", :name => cymru[:net_asn]

    # geolocate
    _log "Geolocating..."
    location_hash = geolocate_ip(lookup_name)
    unless location_hash
      # fall back on cymru country code 
      country_code = cymru[:net_country_code]
      location_hash = {}
      location_hash[:country_code] = country_code
    end
    _set_entity_detail("geolocation", location_hash)

    ### 
    ### Check Whois
    ### 
    if _get_entity_detail "whois_full_text" # skip lookup if we already have it
      _log "Skipping lookup, we already have the details"
      out = @entity.details
    else # do the lookup
      out = whois(lookup_name) || {}
      _set_entity_detail "whois_full_text", out["whois_full_text"]
    end

    whois_text = _get_entity_detail("whois_full_text")    
    if whois_text
      
      # okay now, let's check to see if there's a reference to a netblock here
      netblock_regex = /(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/(\d{1,2}))/
      match_captures = whois_text.scan(netblock_regex)
      match_captures.each do |capture|
        # create it 
        netblock = capture.first
        _log "Found related netblock: #{netblock}"
        _create_entity "NetBlock", "name" => "#{netblock}"
      end

      # check transferred
      if whois_text =~ /Early Registrations, Transferred to/
        _set_entity_detail "transferred", true
      end
    end

    # check ipv6
    if _get_entity_name =~ /::/
      _set_entity_detail "ipv6", true
    end

    ####
    ### Set details for this entity
    ####
    dns_entries = []
    results.each do |result|

      # Clean up the dns data
      xtype = result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode
      xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode

      dns_entries << { "response_data" => xdata, "response_type" => xtype }
    end

    _set_entity_detail("resolutions", dns_entries.uniq )

    ###
    ### Finally, cloud provider determination
    ###

    # Now that we have our core details, check cloud status
    #cloud_providers = determine_cloud_status(@entity)
    #_set_entity_detail "cloud_providers", cloud_providers.uniq.sort
    #_set_entity_detail "cloud_hosted",  !cloud_providers.empty?

  end

end
end
end
end