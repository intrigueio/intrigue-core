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
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}}],
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
      if "#{result["name"]}".is_ip_address?
        _create_entity("IpAddress", { "name" => result["name"] }, @entity)
      else
        _create_entity("DnsRecord", { "name" => result["name"] }, @entity)
      end
    end

    # geolocate
    _log "Geolocating..."
    location_hash = geolocate_ip(lookup_name)

    # get ASN
    # look up the details in team cymru's whois
    _log "Using Team Cymru's Whois Service..."
    whois_details = Intrigue::Client::Search::Cymru::IPAddress.new.whois(lookup_name)
    whois_asn = "AS#{whois_details.first}"
    whois_network = whois_details[1]

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

    # check transferred
    if out["whois_full_text"] =~ /Early Registrations, Transferred to/
      _set_entity_detail "transferred", true
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
    _set_entity_detail("geolocation", location_hash)
    _set_entity_detail("asn", whois_asn)
    _set_entity_detail("network", whois_network)

  end

end
end
end
end