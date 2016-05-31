require 'resolv'
module Intrigue
class DnsLookupReverseTask < BaseTask

  def metadata
    {
      :version => "1.0",
      :name => "dns_lookup_reverse",
      :pretty_name => "DNS Reverse Lookup",
      :authors => ["jcran"],
      :description => "Look up the name of the given ip address.",
      :references => [],
      :allowed_types => ["IpAddress"],
      :example_entities => [{"type" => "IpAddress", "attributes" => {"name" => "192.0.78.13"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    address = _get_entity_attribute "name"

    begin
      resolved_name = Resolv.new([Resolv::DNS.new(:nameserver => opt_resolver,:search => [])]).getname(address).to_s

      if resolved_name
        _log_good "Creating domain #{resolved_name}"

        # Create our new dns record entity with the resolved name
        _create_entity("DnsRecord", {"name" => resolved_name})

      else
        _log "Unable to find a name for #{address}"
      end
      
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    rescue Exception => e
      _log_error "Hit exception: #{e}"
    end
  end

end
end
