require 'dnsruby'

module Intrigue
class EnrichDnsRecord < BaseTask
  include Intrigue::Task::Helper
  include Intrigue::Task::Data

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
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
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

      ip_addresses = []
      dns_names = []

      ########################
      ## Handle ANY Records ##
      ########################
      result = resolver.query(lookup_name, Dnsruby::Types::ANY)

      # Let us know if we got an empty result
      _log "No ANY records!" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::SOA
        next if resource.type == Dnsruby::Types::RRSIG # TODO parsing this out is a pain, not sure if it's valuable
        next if resource.type == Dnsruby::Types::NS
        next if resource.type == Dnsruby::Types::TXT # TODO - let's parse this out?
        next if resource.type == Dnsruby::Types::HINFO # TODO - let's parse this out?

        _log "Got resource: #{resource}"

        if resource.respond_to? :address
          _log "Adding name: #{resource.address}"
          ip_addresses << "#{resource.address}"
        end

        if resource.respond_to? :domainname
          _log "Adding name: #{resource.domainname}"
          dns_names << "#{resource.domainname}"
        end

        if resource.respond_to? :name
          _log "Adding name: #{resource.name}"
          dns_names << "#{resource.name}"
        end

      end #end result.answer

      ##########################
      ##   Handle A Records   ##
      ##########################
      result = resolver.query(lookup_name, Dnsruby::Types::A)

      # Let us know if we got an empty result
      _log "No A records!" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        _log "Adding name from: #{resource}"
        ip_addresses << resource.address.to_s if resource.respond_to? :address
        dns_names << resource.domainname.to_s if resource.respond_to? :domainname
        dns_names << resource.name.to_s.downcase  if resource.respond_to? :name
      end #end result.answer

      ##########################
      ## Handle CNAME Records ##
      ##########################
      result = resolver.query(lookup_name, Dnsruby::Types::CNAME)

      # Let us know if we got an empty result
      _log "No CNAME records!" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        _log "Adding name from: #{resource}"
        ip_addresses << resource.address.to_s if resource.respond_to? :address
        dns_names << resource.domainname.to_s if resource.respond_to? :domainname
        dns_names << resource.name.to_s.downcase if resource.respond_to? :name
      end #end result.answer


      ####
      ### Create entities
      ####

      # check and merge if the ip is associated with another entity!
      ip_addresses.sort.uniq.each do |name|

        # Skipping entities labeled as hidden
        if hidden_entity?(name) && opt_skip_hidden
          _log "Skipping hidden entity: #{name}"
          next
        end

        sub_entity = entity_exists?(@entity.project,"IpAddress",name)
        unless sub_entity
          _log "Creating entity for IpAddress: #{name}"
          sub_entity = _create_entity("IpAddress", { "name" => name }, @entity)
        end

        # skip if we have the same name or the same entity
        next if sub_entity.name == @entity.name
        next if @entity.aliases.include? sub_entity

        _log "Attaching entity: #{sub_entity} to #{@entity}"
        @entity.add_alias sub_entity
        @entity.save

        _log "Attaching entity: #{@entity} to #{sub_entity}"
        sub_entity.add_alias @entity
        sub_entity.save
      end

      # check and merge if the ip is associated with another entity!
      dns_names.sort.uniq.each do |name|

        # Skipping entities labeled as hidden
        if hidden_entity?(name) && opt_skip_hidden
          _log "Skipping hidden entity: #{name}"
          next
        end

        sub_entity = entity_exists?(@entity.project,"DnsRecord",name)
        unless sub_entity
          _log "Creating entity for DnsRecord: #{name}"
          sub_entity = _create_entity("DnsRecord", { "name" => name }, @entity)
        end

        # skip if we have the same name or the same entity
        next if sub_entity.name == @entity.name
        next if @entity.aliases.include? sub_entity

        _log "Attaching entity: #{sub_entity} to #{@entity}"
        @entity.add_alias sub_entity
        @entity.save

        _log "Attaching entity: #{@entity} to #{sub_entity}"
        sub_entity.add_alias @entity
        sub_entity.save

      end

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
