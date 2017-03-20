require 'dnsruby'

module Intrigue
class EnrichHost < BaseTask

  def self.metadata
    {
      :name => "enrich_host",
      :pretty_name => "Enrich Host",
      :authors => ["jcran"],
      :description => "Look up all names of a given entity.",
      :references => [],
      :allowed_types => ["Host"],
      :type => "enrichment",
      :passive => true,
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
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

    ip_addresses = []
    dns_names = []
    if lookup_name.is_ip_address?
      ip_addresses << lookup_name
    else
      dns_names << lookup_name
    end

    begin
      resolver = Dnsruby::Resolver.new(
        :recurse => "true",
        :query_timeout => 5,
        :nameserver => opt_resolver,
        :search => [])

      result = resolver.query(lookup_name)
      _log "Processing: #{result}"

      # Let us know if we got an empty result
      _log_error "Nothing?" if result.answer.empty?

      # For each of the found addresses
      result.answer.map do |resource|
        next if resource.type == Dnsruby::Types::RRSIG #TODO parsing this out is a pain, not sure if it's valuable
        _log "Adding name from: #{resource}"
        ip_addresses << resource.address.to_s if resource.respond_to? :address
        dns_names << resource.name.to_s.downcase
      end #end result.answer

    rescue Dnsruby::ServFail => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::NXDomain => e
      _log_error "Unable to resolve: #{@entity}, error: #{e}"
    rescue Dnsruby::ResolvTimeout => e
      _log_error "Unable to resolve, timed out: #{e}"
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"

    #rescue Exception => e
    #  _log_error "Hit exception: #{e}"
    ensure

      temp_details = @entity.details
      temp_details["ip_addresses"] = ip_addresses.sort.uniq
      temp_details["dns_names"] = dns_names.sort.uniq
      temp_details["enriched"] = true

      @entity.update(:details => temp_details)
      @entity.save

    end

    _log "Ran enrichment task!"
  end

end
end
