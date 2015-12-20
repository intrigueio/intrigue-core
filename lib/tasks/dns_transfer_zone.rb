require 'dnsruby'
require 'whois'
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
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord","Finding","IpAddress"]
    }
  end

  def run
    super

    resolver = _get_option "resolver"
    domain_name = _get_entity_attribute "name"

    authoritative_nameservers = ["#{resolver}"]

    # Get the authoritative nameservers & query each of them
    begin
      timeout(10) do
        answer = Whois::Client.new.lookup(domain_name)
        resolved_list = nil
        if answer.nameservers
          authoritative_nameservers = answer.nameservers
        else
          @task_result.logger.log_error "Unknown nameservers for this domain, using #{authoratative_nameservers}"
        end
      end
    rescue Timeout::Error
      @task_result.logger.log_error "Execution Timed out waiting for an answer from nameserver for #{domain_name}"
    #rescue Exception => e
    #  @task_result.logger.log "Error querying whois: #{e}"
    end

    # For each authoritive nameserver
    authoritative_nameservers.each do |nameserver|
      begin

        timeout(300) do

          @task_result.logger.log "Attempting Zone Transfer on #{domain_name} against nameserver #{nameserver}"

          res = Dnsruby::Resolver.new(
            :nameserver => nameserver.to_s,
            :recurse => true,
            :use_tcp => true,
            :query_timeout => 20)

          axfr_answer = res.query(domain_name, Dnsruby::Types.AXFR)

          # If we got a success to the AXFR query.
          if axfr_answer

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
            # Record keeping
            @task_result.logger.log_good "Zone Tranfer Succeeded on #{domain_name}"
          end
        end

      rescue Timeout::Error
        @task_result.logger.log_error "Task Execution Timed out"
      rescue Dnsruby::Refused
        @task_result.logger.log_error "Zone Transfer against #{domain_name} refused."
      rescue Dnsruby::ResolvError
        @task_result.logger.log_error "Unable to resolve #{domain_name} while querying #{nameserver}."
      rescue Dnsruby::ResolvTimeout
        @task_result.logger.log_error "Timed out while querying #{nameserver} for #{domain_name}."
      #rescue Exception => e
      # @task_result.logger.log_error "Unknown exception: #{e}"
      end
    end
  end


end
end
