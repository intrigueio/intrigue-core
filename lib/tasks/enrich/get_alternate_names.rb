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
      :allowed_types => ["DnsRecord"],
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
      record_types = _get_option "record_types"
      name = _get_entity_name

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
          if  resource.type == Dnsruby::Types::A ||
              resource.type == Dnsruby::Types::AAAA ||
              resource.type == Dnsruby::Types::CNAME
            _log "Adding alias #{resource.rdata}"
            e = _create_alias_entity("IpAddress", {"name" => "#{resource.rdata}"}, @entity)
          end
        end

      rescue Errno::ENETUNREACH => e
        _log_error "Hit exception: #{e}. Are you sure you're connected?"
      rescue Exception => e
        _log_error "Hit exception: #{e}"
      end

    _log "Ran enrichment task!"

  end

end
end
