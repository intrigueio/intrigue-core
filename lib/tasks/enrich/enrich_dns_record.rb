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
    ### Create entities
    ####
    results.each do |result|
      _log "Creating entity for... #{result["name"]}"
      if "#{result["name"]}".is_ip_address?
        _create_entity("IpAddress", { "name" => result["name"] }, @entity)
      else
        _create_entity("DnsRecord", { "name" => result["name"] }, @entity)
      end

    end

    @entity.set_detail("lookup_data", results)
    @entity.save

    _log "Ran enrichment task!"
  end

end
end
end
