require 'dnsruby'

module Intrigue
class DnsTransferZoneTask < BaseTask

  def metadata
    {
      :name => "dns_transfer_zone",
      :pretty_name => "DNS Zone Transfer",
      :authors => ["jcran"],
      :description => "DNS Zone Transfer",
      :allowed_types => ["DnsRecord"],
      :example_entities => [
        {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}
      ],
      :allowed_options => [ ],
      :created_types => ["DnsRecord","Info","IpAddress"]
    }
  end

  def run
    super

    domain_name = _get_entity_attribute "name"

    # Get the nameservers
    authoritative_nameservers = Resolv::DNS.open do |dns|
      records = dns.getresources(domain_name, Resolv::DNS::Resource::IN::NS)
      records.empty? ? [] : records.map {|x| x.name.to_s}
    end

    # For each authoritive nameserver
    authoritative_nameservers.each do |nameserver|
      begin

        @task_result.logger.log "Attempting Zone Transfer on #{domain_name} against nameserver #{nameserver}"

        #res = Dnsruby::Resolver.new(
        #  :nameserver => nameserver,
        #  :use_tcp => true,
        #  :query_timeout => 20)

        #axfr_answer = res.query(domain_name, Dnsruby::Types.AXFR)
        #ixfr_answer = res.query(domain_name, Dnsruby::Types.IXFR)

        #@task_result.logger.log "AXFR Response: #{axfr_answer.answer}" if axfr_answer
        #@task_result.logger.log "IXFR Response: #{ixfr_answer.answer}" if ixfr_answer

        # If we got a success to the AXFR query.
        #if axfr_answer.answer.length > 0

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
            if z.type == "A"
              _create_entity "IpAddress", { "name" => z.address.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
              _create_entity "DnsRecord", { "name" => z.name.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
            elsif z.type == "CNAME"
              _create_entity "DnsRecord", { "name" => z.name.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
              _create_entity "DnsRecord", { "name" => z.rdata.to_s, "type" => z.type.to_s, "content" => "#{z.rdata}" }
            elsif z.type == "NS"
              _create_entity "DnsRecord", { "name" => z.name.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
              # XXX - it's possible rdata could contain an IP address, we should check for this
              _create_entity "DnsRecord", { "name" => z.rdata.to_s, "type" => z.type.to_s, "content" => "#{z.rdata}" }
            else
              _create_entity "DnsRecord", { "name" => z.name.to_s, "type" => z.type.to_s, "content" => "#{z.to_s}" }
            end
          end
        #end

      rescue Dnsruby::Refused => e
        @task_result.logger.log "Zone Transfer against #{domain_name} refused: #{e}"
      rescue Dnsruby::ResolvError => e
        @task_result.logger.log "Unable to resolve #{domain_name} while querying #{nameserver}: #{e}"
      rescue Dnsruby::ResolvTimeout =>  e
        @task_result.logger.log "Timed out while querying #{nameserver} for #{domain_name}: #{e}"
      rescue Errno::EHOSTUNREACH => e
        @task_result.logger.log_error "Unable to connect: (#{e})"
      rescue Errno::ECONNREFUSED => e
        @task_result.logger.log_error "Unable to connect: (#{e})"
      rescue Errno::ECONNRESET => e
        @task_result.logger.log_error "Unable to connect: (#{e})"
      rescue Errno::ETIMEDOUT => e
        @task_result.logger.log_error "Unable to connect: (#{e})"
      end # end begin

    end # end .each

  end # end run



end
end
