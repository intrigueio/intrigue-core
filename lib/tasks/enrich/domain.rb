module Intrigue
module Task
module Enrich
class Domain < Intrigue::Task::BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "enrich/domain",
      :pretty_name => "Enrich Domain",
      :authors => ["jcran"],
      :description => "Fills in details for a Domain",
      :references => [],
      :allowed_types => ["Domain"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "Domain", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run

    # cache this to save lookups, and note that we can't use the 
    # stored value for scoped yet, as it is not yet fully determined
    # so... we'll use the best info available, by checking the scoped? method
    entity_scoped = @entity.scoped? 

    lookup_name = _get_entity_name

    # get our resolutiosn
    results = resolve(lookup_name)

    ####
    ### Create aliased entities
    #### 
    new_entity = create_dns_aliases(results, @entity) if entity_scoped
    
    if !new_entity.nil? && new_entity.length > 0
      _log "Geolocating..."
      location_hash = geolocate_ip(new_entity.first["name"]) unless new_entity.first["name"].nil?
      if location_hash.nil? 
        _log "Unable to retrieve Gelocation."
      else
        _set_entity_detail("geolocation", location_hash)
      end
    end

    resolutions = collect_resolutions(results)
    _set_entity_detail("resolutions", resolutions )
    
    resolutions.each do |r|
      # create unscoped domains for all CNAMEs
      if r["response_type"] == "CNAME" && entity_scoped
        create_dns_entity_from_string(r["response_data"]) 
      end
    end

    # grab any / all SOA record
    _log "Grabbing SOA"
    soa_details = collect_soa_details(lookup_name)
    _set_entity_detail("soa_record", soa_details)
    if soa_details && soa_details["primary_name_server"] && entity_scoped
      _create_entity "Nameserver", "name" => soa_details["primary_name_server"]
    end

    # grab whois info & all nameservers
    if soa_details
      out = whois(lookup_name)
      if out && out.first
        _set_entity_detail("whois_full_text", out.first["whois_full_text"])
        _set_entity_detail("contacts", out.first["contacts"])
      end
    end

    _log "Grabbing Nameservers"
    ns_records = collect_ns_details(lookup_name)
    _set_entity_detail("nameservers", ns_records)
    
    # make sure we create affiliated domains
    ns_records.each do |ns|
      _create_entity "Nameserver", "name" => ns if entity_scoped
    end

    # grab any / all MX records (useful to see who accepts mail)
    _log "Grabbing MX"
    mx_records = collect_mx_records(lookup_name)
    _set_entity_detail("mx_records", mx_records)
    mx_records.each{|mx| 
      next unless entity_scoped
      create_unscoped_dns_entity_from_string(mx["host"])
    }

    # collect TXT records (useful for random things)
    _log "Grabbing TXT Records"
    _set_entity_detail("txt_records", collect_txt_records(lookup_name))

    # grab any / all SPF records (useful to see who accepts mail)
    _log "Grabbing SPF Records"
    spf_details = collect_spf_details(lookup_name)
    _set_entity_detail("spf_record", spf_details)
    spf_details.each do |record|
      record.split(" ").each do |spf|
        next unless entity_scoped
        next unless spf.match(/^include:/)
        domain_name = spf.split("include:").last
        _log "Found Associated SPF Domain: #{domain_name}"
        create_unscoped_dns_entity_from_string(domain_name)
      end
    end

    # Collect DMARC info 
    _log "Grabbing DMARC Details"
    dmarc_record_name = "_dmarc.#{_get_entity_name}"
    result = resolve(dmarc_record_name, [Resolv::DNS::Resource::IN::TXT])
    if result.count > 0 # No record!
      # set dmarc to the first record we get back 
      dmarc_details = result.first["lookup_details"].first["response_record_data"]
      _set_entity_detail("dmarc", dmarc_details)

      # parse up the 'rua' component into email addresses
      dmarc_details.split(";").each do |component|
        
        # https://dmarcian.com/rua-vs-ruf/
        if component.strip.match(/^rua/) || component.strip.match(/^ruf/)
          component.split("mailto:").last.split(",").each do |address|
            next unless entity_scoped
            _create_entity "EmailAddress", :name => address
          end
        end

      end
    else 

      # Set DMARC empty
      _set_entity_detail("dmarc", nil) 

      # if we have mx records and we're scoped, create an issue
      if mx_records.count > 0 && entity_scoped
        _create_dmarc_issues(mx_records, dmarc_details)
      end

    end

    ###
    ### Create vhost by creating network service entity (which 
    ### will automatically look at all aliases of this entity)
    ###
    if entity_scoped
      (_get_entity_detail("ports") || [] ).each do |p|
        
        # only web ports 
        next unless scannable_web_ports.include? p["number"]
      
        # skip if we already have a uri
        proto = "#{p["number"]}" =~ /443/ ? "https" : "http"
        next if entity_exists?(@project, "Uri", "#{proto}://#{lookup_name}:#{p["number"]}")
        
        _create_network_service_entity a, p["number"], p["protocol"] 
      end 
    end

  end


end
end
end
end