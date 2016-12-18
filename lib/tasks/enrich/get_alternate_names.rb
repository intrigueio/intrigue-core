require 'dnsruby'

module Intrigue
class GetAlternateNames < BaseTask

  def self.metadata
    {
      :name => "get_alternate_names",
      :type => "enrichment",
      :pretty_name => "Get Alternate Names",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["DnsRecord", "IpAddress"],
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
    name = _get_entity_name

    if @entity.type_string == "DnsRecord"
      begin
      result = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => opt_resolver,
        :search => [])

      result = result.query(name)
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        _log "Adding alias for #{resource.rdata}"
        if (resource.type == Dnsruby::Types::A ||
            resource.type == Dnsruby::Types::AAAA)
          e = _create_alias_entity("IpAddress", {"name" => "#{resource.rdata}"}, @entity)
        else
          e = _create_alias_entity("DnsRecord", {"name" => "#{resource.rdata}"}, @entity)
        end
      end

      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      rescue Exception => e
        _log_error "Hit exception: #{e}"
      end
    else #IPADDRESS
      require 'resolv'
      begin
        resolved_name = Resolv.new([Resolv::DNS.new(:nameserver => opt_resolver,:search => [])]).getname(name).to_s
        if resolved_name
          _log_good "Creating domain #{resolved_name}"
          # Create our new dns record entity with the resolved name
          _create_alias_entity("DnsRecord", {"name" => resolved_name}, @entity)
        else
          _log "Unable to find a name for #{address}"
        end
      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      rescue Exception => e
        _log_error "Hit exception: #{e}"
      end
    end

    _log "Ran enrichment task!"

  end

end
end
