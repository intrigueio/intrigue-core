module Intrigue
module Task
class DnsTransferZone < BaseTask

  def self.metadata
    {
      :name => "dns_transfer_zone",
      :pretty_name => "DNS Zone Transfer",
      :authors => ["jcran"],
      :description => "DNS Zone Transfer",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :type => "discovery",
      :passive => false,
      :example_entities => [
        {"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [ ],
      :created_types => ["DnsRecord","Info"]
    }
  end

  def run
    super

    domain_name = _get_entity_name

    # Get the nameservers
    authoritative_nameservers = []
    Resolv::DNS.open do |dns|
      resources = dns.getresources(domain_name, Resolv::DNS::Resource::IN::NS)
      resources.each do |r|
        dns.each_resource(r.name, Resolv::DNS::Resource::IN::A){ |x| authoritative_nameservers << x.address.to_s }
      end
    end

    # For each authoritive nameserver
    authoritative_nameservers.each do |nameserver|
      begin

        _log "Attempting Zone Transfer on #{domain_name} against nameserver #{nameserver}"

        # Do the actual zone transfer
        zt = Dnsruby::ZoneTransfer.new
        zt.transfer_type = Dnsruby::Types.AXFR
        zt.server = nameserver
        zone = zt.transfer(domain_name)

        _create_entity "Info", {
          "name" => "Zone Transfer",
          "content" => "#{nameserver} -> #{domain_name}",
          "details" => zone
        }

        # Create host records for each item in the zone
        zone.each do |z|
          if z.type == "SOA" || z.type == "TXT"
            _create_entity "DnsRecord", { "name" => z.name.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
          else
            # Check to see what type this record's content is.
            # MX records are of form: [10, #<Dnsruby::Name: vv-cephei.ac-grenoble.fr.>
            z.rdata.respond_to?("last") ? record = "#{z.rdata.last.to_s}" : record = "#{z.rdata.to_s}"

            # Check to see if it's an ip address or a dns record
            #record.is_ip_address? ? entity_type = "IpAddress" : entity_type = "DnsRecord"
            _create_entity "DnsRecord", { "name" => "#{record}", "type" => "#{z.type.to_s}", "content" => "#{record}" }
          end
        end

      rescue Dnsruby::Refused => e
        _log "Zone Transfer against #{domain_name} refused: #{e}"
      rescue Dnsruby::ResolvError => e
        _log "Unable to resolve #{domain_name} while querying #{nameserver}: #{e}"
      rescue Dnsruby::ResolvTimeout =>  e
        _log "Timed out while querying #{nameserver} for #{domain_name}: #{e}"
      rescue Errno::EHOSTUNREACH => e
        _log_error "Unable to connect: (#{e})"
      rescue Errno::ECONNREFUSED => e
        _log_error "Unable to connect: (#{e})"
      rescue Errno::ECONNRESET => e
        _log_error "Unable to connect: (#{e})"
      rescue Errno::ETIMEDOUT => e
        _log_error "Unable to connect: (#{e})"
      end # end begin
    end # end .each
  end # end run



end
end
end
