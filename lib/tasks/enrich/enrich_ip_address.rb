require 'dnsruby'

module Intrigue
class EnrichIpAddress < BaseTask
  include Intrigue::Task::Helper
  include Intrigue::Task::Data

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
      :example_entities => [{"type" => "IpAddress", "attributes" => {"name" => "8.8.8.8"}}],
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

    begin
      resolver = Dnsruby::Resolver.new(
        :nameserver => opt_resolver,
        :search => [])

      result = resolver.query(lookup_name, Dnsruby::Types::PTR)
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log "No PTR records!" if result.answer.empty?

      ip_addresses = []
      dns_names = []

      # For each of the found addresses
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::RRSIG # TODO parsing this out is a pain, not sure if it's valuable
        next if resource.type == Dnsruby::Types::NS
        next if resource.type == Dnsruby::Types::TXT # TODO - let's parse this out?

        _log "Adding name from: #{resource}"
        ip_addresses << resource.address.to_s if resource.respond_to? :address
        dns_names << resource.domainname.to_s if resource.respond_to? :domainname
        dns_names << resource.name.to_s.downcase
      end #end result.answer

      dns_names.sort.uniq.each do |name|

        if hidden_entity?(name) && opt_skip_hidden
          _log "Skipping hidden entity: #{name} #{opt_skip_hidden}"
          next
        end

        sub_entity = entity_exists?(@entity.project,"DnsRecord",name)
        unless sub_entity
          _log "Creating entity for DnsRecord: #{name}"
          sub_entity = _create_entity("DnsRecord", {"name" => name }, @entity)
        end

        # skip if we have the same name or the same entity
        next unless sub_entity
        next if sub_entity.name == @entity.name
        next if @entity.aliases.include? sub_entity

        _log "Attaching entity: #{sub_entity} to #{@entity}"
        @entity.add_alias sub_entity
        @entity.save

        _log "Attaching entity: #{@entity} to #{sub_entity}"
        sub_entity.add_alias @entity
        sub_entity.save
      end

    rescue Dnsruby::SocketEofResolvError => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::ServFail => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::NXDomain => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::ResolvTimeout => e
      _log_error "Unable to resolve, timed out: #{e}"
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    ensure
      @entity.enriched = true
      @entity.save
    end

    _log "Ran enrichment task!"
  end

end
end
