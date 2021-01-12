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

    lookup_name = _get_entity_name

    # Do a lookup, skip if we already have it (TLD case)
    unless _get_entity_detail("resolutions")

      results = resolve(lookup_name)
      _create_aliases results

      resolutions = collect_resolutions(results)
      _set_entity_detail("resolutions", resolutions )
      resolutions.each do |r|
        # create unscoped domains for all CNAMEs
        if r["response_type"] == "CNAME"
          create_dns_entity_from_string(r["response_data"]) 
        end
      end

      # grab any / all SOA record
      _log "Grabbing SOA"
      soa_details = collect_soa_details(lookup_name)
      _set_entity_detail("soa_record", soa_details)
      if soa_details && soa_details["primary_name_server"] && @entity.scoped?
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
        if @entity.scoped?
          _create_entity "Nameserver", "name" => ns
        end
      end

      # grab any / all MX records (useful to see who accepts mail)
      _log "Grabbing MX"
      mx_records = collect_mx_records(lookup_name)
      _set_entity_detail("mx_records", mx_records)
      mx_records.each{|mx| create_dns_entity_from_string(mx["host"]) }

      # collect TXT records (useful for random things)
      _log "Grabbing TXT Records"
      _set_entity_detail("txt_records", collect_txt_records(lookup_name))

      # grab any / all SPF records (useful to see who accepts mail)
      _log "Grabbing SPF Records"
      spf_details = collect_spf_details(lookup_name)
      _set_entity_detail("spf_record", spf_details)
      spf_details.each do |record|
        record.split(" ").each do |spf|
          next unless spf.match(/^include:/)
          domain_name = spf.split("include:").last
          _log "Found Associated SPF Domain: #{domain_name}"
          create_dns_entity_from_string(domain_name) if @entity.scoped?
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
              _create_entity "EmailAddress", :name => address if @entity.scoped?
            end
          end

        end
      else 

        # Set DMARC empty
        _set_entity_detail("dmarc", nil) 

        # if we have mx records and we're scoped, create an issue
        if mx_records.count > 0 && @entity.scoped?
          _create_dmarc_issues(mx_records, dmarc_details)
        end

      end

    end

    ###
    ### Scope all aliases if we're scoped ... note this might be unnecessary
    ###  / duplicative of what's happening in the IpAddress entity scoping logic 
    ###  itself. TODO ... investigate 
    ###
    if @entity.scoped? && @entity.aliases.count > 1
      @entity.aliases.each do |a|
        next if a.id == @entity.id # we're already scoped. 
        next unless a.type_string == "IpAddress" #only proceed for ip addresses
        
        # set scoped unless this belongs to a known global entity
          _log "Setting #{a.name} scoped!"
          a.set_scoped!(true, "alias_of_entity_#{@task_result.name}")         
      end
    end 

  end

  private

  def _create_aliases(results)
    ####
    ### Create aliased entities
    ####
    results.each do |result|
      next if @entity.name == result["name"]
      _log "Creating entity for... #{result}"
    
      # create a domain for this entity
      entity = create_dns_entity_from_string(result["name"], @entity)
    end

  end


end
end
end
end