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

    lookup_name = _get_entity_name

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
    location_hash = geolocate_ip(lookup_name)

    ####
    ### Set details for this entity
    ####
    dns_entries = []
    results.each do |result|

      # Clean up the dns data
      xtype = result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode

      lookup_details = result["lookup_details"].first["response_record_data"]
      if lookup_details.kind_of?(Dnsruby::IPv4) || lookup_details.kind_of?(Dnsruby::IPv6) || lookup_details.kind_of?(Dnsruby::Name)
        _log "Sanitizing Dnsruby Object"
        xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
      else
        _log "Sanitizing String or array"
        xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
      end

      dns_entries << { "response_data" => xdata, "response_type" => xtype }
    end

    _set_entity_detail("resolutions", dns_entries.uniq )
    _set_entity_detail("geolocation", location_hash)

    # scoping ... HACKY
    if @entity.created_by? "masscan_scan"
      @entity.scoped = true
      @entity.save
    end

  end

end
end
end
end