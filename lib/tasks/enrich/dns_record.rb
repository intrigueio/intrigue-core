module Intrigue
module Task
module Enrich
class DnsRecord < Intrigue::Task::BaseTask
  
  def self.metadata
    {
      :name => "enrich/dns_record",
      :pretty_name => "Enrich DnsRecord",
      :authors => ["jcran"],
      :description => "Fills in details for a DnsRecord",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => [
        "DnsRecord",
        "Domain",
        "IpAddress",
        "NetworkService"
      ]
    }
  end

  def run
    lookup_name = _get_entity_name

    # always create a domain 
    create_dns_entity_from_string(parse_domain_name(lookup_name))

    # Do a lookup and keep track of all aliases
    _log "Resolving: #{lookup_name}"
    results = resolve(lookup_name)

    _log "Creating aliases for #{@entity.name}"
    _create_aliases(results) if @entity.scoped

    return unless results.count > 0

    # Create new entities if we found vhosts / aliases
    _log "Creating vhost services"
    _create_vhost_entities(lookup_name) if @entity.scoped

    _log "Grabbing resolutions"
    resolutions = collect_resolutions(results)

    _set_entity_detail("resolutions", resolutions)

    _log "Grabbing SOA"
    soa_details = collect_soa_details(lookup_name)
    _set_entity_detail("soa_record", soa_details)
    if soa_details && soa_details["primary_name_server"]
      if @entity.scoped
        _create_entity "Nameserver", "name" => soa_details["primary_name_server"]
      end
    end

    # Checking dev test 
    # if we're external, let's see if this matches 
    # a known dev or staging server pattern
    if !match_rfc1918_address?(resolutions.map{|x| x["response_data"]}.join(", "))
      dev_server_name_patterns.each do |p|
        if "#{lookup_name}".split(".").first =~ p
          _exposed_server_identified(p)
        end
      end
    end

    if soa_details

      # grab any / all MX records (useful to see who accepts mail)
      _log "Grabbing MX"
      mx_records = collect_mx_records(lookup_name)
      _set_entity_detail("mx_records", mx_records)
      mx_records.each{|mx| create_dns_entity_from_string(mx["host"]) if @entity.scoped }

      # collect TXT records (useful for random things)
      _log "Grabbing TXT"
      txt_records = collect_txt_records(lookup_name)
      _set_entity_detail("txt_records", txt_records)

      # grab any / all SPF records (useful to see who accepts mail)
      _log "Grabbing SPF"
      spf_details = collect_spf_details(lookup_name)
      _set_entity_detail("spf_record", spf_details)

    end

    ###
    ### Finally, cloud provider determination
    ###

    # Now that we have our core details, check cloud status
    #cloud_providers = determine_cloud_status(@entity)
    #_set_entity_detail "cloud_providers", cloud_providers.uniq.sort
    #_set_entity_detail "cloud_hosted",  !cloud_providers.empty?

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

    def _create_vhost_entities(lookup_name)
      ### For each associated IpAddress, make sure we create any additional
      ### uris if we already have scan results
      ###
      @entity.aliases.each do |a|
        next unless a.type_string == "IpAddress" #  only ips
        existing_ports = a.get_detail("ports")
        if existing_ports
          existing_ports.each do |p|
            _create_network_service_entity(a,p["number"],p["protocol"],{})
          end
        end
      end
    end


end
end
end
end