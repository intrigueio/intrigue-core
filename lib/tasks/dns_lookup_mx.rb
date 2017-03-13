require 'resolv'
module Intrigue
class DnsLookupMxTask < BaseTask

  def self.metadata
    {
      :name => "dns_lookup_mx",
      :pretty_name => "DNS MX Lookup",
      :authors => ["jcran"],
      :description => "Look up the MX records of the given DNS record.",
      :references => [],
      :type => "discovery",
      :passive => true,
      :allowed_types => ["DnsRecord","Host"],
      :example_entities => [{"type" => "Host", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord","Host","IpAddress"]
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    name = _get_entity_name

    begin
      # XXX - we should probably call this a couple times to deal
      # with round-robin DNS & load balancers. We'd need to merge results
      # across the queries
      resources = Resolv::DNS.open(:nameserver => opt_resolver,:search => []) do |dns|
        dns.getresources(name, Resolv::DNS::Resource::IN::MX)
      end

      resources.each do |r|

        # Create a DNS record
        _create_entity("Host", {
          "name" => r.exchange.to_s,
          "description" => "Mail server for #{name}",
          "preference" => r.preference })

      end
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    rescue Exception => e
      _log_error "Hit exception: #{e}"
    end
  end

end
end
