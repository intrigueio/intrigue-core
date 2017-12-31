module Intrigue
module Task
class EnrichDnsRecord < BaseTask
  include Intrigue::Task::Helper
  include Intrigue::Task::Data
  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "enrich_dns_record",
      :pretty_name => "Enrich DnsRecord",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => []
    }
  end

  def run
    super

    lookup_name = _get_entity_name

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
    dns_entries = results.map { |result|
      { "response_data" => result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode,
        "response_type" => result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode }
    }.uniq{ |r| "#{r["response_data"]}-#{r["response_type"]}" }

    @entity.set_detail("dns_entries", dns_entries)
    @entity.save

    _log "Ran enrichment task!"
  end

end
end
end
