require 'dnsruby'

module Intrigue
class EnrichDnsRecord < BaseTask
  include Intrigue::Task::Helper

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
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => []
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    lookup_name = _get_entity_name

    begin

      resolver = Dnsruby::Resolver.new(
        :nameserver => opt_resolver,
        :search => [])

      ######################
      ## Handle A Records ##
      ######################
      result = resolver.query(lookup_name, Dnsruby::Types::A)

      # Let us know if we got an empty result
      _log "No A records!" if result.answer.empty?

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

      # check and merge if the ip is associated with another entity!
      ip_addresses.sort.uniq.each do |name|

        sub_entity = entity_exists?(@entity.project,"IpAddress",name)
        unless sub_entity
          _log "Creating entity for IpAddress: #{name}"
          sub_entity = _create_entity("IpAddress", {"name" => name}, @entity)
        end

        _log "Attaching entity: #{sub_entity} to #{@entity}"
        @entity.add_alias sub_entity
        @entity.save

        _log "Attaching entity: #{@entity} to #{sub_entity}"
        sub_entity.add_alias @entity
        sub_entity.save

      end

      ##########################
      ## Handle CNAME Records ##
      ##########################
      result = resolver.query(lookup_name, Dnsruby::Types::CNAME)

      # Let us know if we got an empty result
      _log "No CNAME records!" if result.answer.empty?

      dns_names = []

      # For each of the found addresses
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::RRSIG # TODO parsing this out is a pain, not sure if it's valuable
        next if resource.type == Dnsruby::Types::NS
        next if resource.type == Dnsruby::Types::TXT # TODO - let's parse this out?

        dns_names << resource.domainname.to_s if resource.respond_to? :domainname
        dns_names << resource.name.to_s.downcase
        end #end result.answer

      # check and merge if the ip is associated with another entity!
      dns_names.sort.uniq.each do |name|

        next if name =~ /.*\.arpa$/
        next if name =~ /.*\.edgekey.net$/
        next if name =~ /.*\.akamaiedge.net$/
        next if name =~ /.*\.akamaitechnologies.com$/

        sub_entity = entity_exists?(@entity.project,"DnsRecord",name)
        unless sub_entity
          _log "Creating entity for DnsRecord: #{name}"
          sub_entity = _create_entity("DnsRecord", {"name" => name}, @entity)
        end

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
      @entity.set_detail("enriched", true)
      @entity.save
    end

    _log "Ran enrichment task!"
  end

end
end
