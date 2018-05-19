module Intrigue
module Task
class EnrichIpAddress < BaseTask

  def self.metadata
    {
      :name => "enrich/ip_address",
      :pretty_name => "Enrich IP Address",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["IpAddress"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "IpAddress", "details" => {"name" => "8.8.8.8"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "skip_hidden", :type => "Boolean", :regex => "boolean", :default => false }
      ],
      :created_types => []
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    opt_skip_hidden = _get_option "skip_hidden"
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
    results = resolve(lookup_name, Dnsruby::Types::ANY)
    results.concat(resolve(lookup_name, Dnsruby::Types::A))
    results.concat(resolve(lookup_name, Dnsruby::Types::CNAME))

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

    _set_entity_detail("dns_entries", dns_entries.uniq )

    _finalize_enrichment
  end

end
end
end
