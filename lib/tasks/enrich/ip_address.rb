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
    if @entity.name.match(/:/)
      _set_entity_detail("version",6)
    else
      _set_entity_detail("version",4)
    end

    ########################
    ## Handle ANY Records ##
    ########################
    results = resolve(lookup_name)
    
    ####
    ### Create aliased entities
    #### 
    results.each do |result|
      _log "Creating entity for... #{result["name"]}"

      next unless result
      next unless result["name"]
      next unless result["name"].length > 0

      # create a domain for this entity
      entity = create_dns_entity_from_string(result["name"], @entity) if @entity.scoped?
      
      if entity && entity.type_string == "Domain"
        
        # unscope it right away, since this can cause scope issues 
        # ... not auto-unscoping it can lead us into trouble (digitalwarlock.com)
        # ... 67.225.252.85
        entity.set_scoped!(false, "Domain found during ip lookup, preventing auto-expand")
        entity.save_changes

      else  # always create a domain for this entity in case the above was a subdomain
        domain_name = parse_domain_name(result["name"])
        create_unscoped_dns_entity_from_string(domain_name)
      end

      # if we're external, let's see if this matches 
      # a known dev or staging server pattern, and if we're internal, just
      if match_rfc1918_address?(lookup_name)
        _log "Got RFC1918 address!"

        # TODO ... _internal_system_exposed_via_dns(result["name"])
        
      else # normal case
        dev_server_name_patterns.each do |p|
          if "#{result["name"]}".split(".").first.match(p)
            _exposed_server_identified(p, result["name"])
          end
        end
      end

    end

    # Create new entities if we found vhosts / aliases
    _log "Creating services for all aliases (vhosts) of #{lookup_name}"
    _create_vhost_entities(lookup_name)
        
    # get ASN
    cymru = cymru_ip_whois_lookup(lookup_name)
    _set_entity_detail "net_name", cymru[:net_name] # legacy 

    # Go forward detail naming scheme
    _set_entity_detail "network.allocation_date", cymru[:net_allocation_date] 
    _set_entity_detail "network.asn", cymru[:net_asn]
    _set_entity_detail "network.block", cymru[:net_block]
    _set_entity_detail "network.country_code", cymru[:net_country_code]
    _set_entity_detail "network.name", cymru[:net_name]
    _set_entity_detail "network.rir", cymru[:net_rir]
    
    # geolocate
    _log "Geolocating..."
    location_hash = geolocate_ip(lookup_name)
    _set_entity_detail("geolocation", location_hash)

    ### 
    ### Check Whois
    ### 
    if _get_entity_detail "whois_full_text" # skip lookup if we already have it
      _log "Skipping lookup, we already have the details"
      out = @entity.details
    else # do the lookup
      out = whois(lookup_name)
      if out != nil
        if out.first != nil
          _set_entity_detail "whois_full_text", out.first["whois_full_text"]  
        end
      end
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
        # Note that everything created from enrich is autoscoped, so specifically
        # unscope this. If it gets scoped later, all the better
        if @entity.scoped
          _create_entity "NetBlock", { "name" => "#{netblock}", "unscoped" => true }
        end
      end

      # check transferred
      if whois_text.match(/Early Registrations, Transferred to/)
        _set_entity_detail "transferred", true
      end
    end

    # check ipv6
    if _get_entity_name.match(/::/)
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