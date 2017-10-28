module Intrigue
module Task
class EnrichIpAddress < BaseTask
  include Intrigue::Task::Helper
  include Intrigue::Task::Data
  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "enrich_ip_address",
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
      @entity.set_detail("version",6)
    else
      @entity.set_detail("version",4)
    end

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
