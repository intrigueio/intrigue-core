require 'dnsruby'
require 'whois'

class DnsTransferZoneTask < BaseTask

  def metadata
    {
      :name => "dns_transfer_zone",
      :pretty_name => "DNS Zone Transfer",
      :authors => ["jcran"],
      :description => "DNS Zone Transfer",
      :allowed_types => ["DnsRecord"],
      :example_entities => [
        {:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}
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
          @task_log.error "Unknown nameservers for this domain, using #{authoratative_nameservers}"
        end
      end
    rescue Timeout::Error
      @task_log.error "Execution Timed out waiting for an answer from nameserver for #{domain_name}"
    rescue Exception => e
      @task_log.log "Error querying whois: #{e}"
    end

    # For each authoritive nameserver
    authoritative_nameservers.each do |nameserver|
      begin

        timeout(30) do

          @task_log.log "Attempting Zone Transfer on #{domain_name} against nameserver #{nameserver}"

          res = Dnsruby::Resolver.new(
            :nameserver => nameserver.to_s,
            :recurse => true,
            :use_tcp => true,
            :query_timeout => 10)

          axfr_answer = res.query(domain_name, Dnsruby::Types.AXFR)

          # If we got a success to the AXFR query.
          if axfr_answer

            # Do the actual zone transfer
            zt = Dnsruby::ZoneTransfer.new
            zt.transfer_type = Dnsruby::Types.AXFR
            zt.server = nameserver
            zone = zt.transfer(domain_name)

            _create_entity "Info", {
              :name => "Zone Transfer",
              :content => "#{nameserver} -> #{domain_name}",
              :details => zone
            }

            # Create host records for each item in the zone
            zone.each do |z|
              if z.type == "A"
                _create_entity "IpAddress", { :name => z.address.to_s }
                _create_entity "DnsRecord", { :name => z.name.to_s, :type => "A" }
              elsif z.type == "CNAME"
                # TODO - recursively lookup CNAME host
                _create_entity "DnsRecord", { :name => z.name.to_s, :type => "CNAME" }
              elsif z.type == "MX"
                _create_entity "DnsRecord", { :name => z.name.to_s, :type => "MX"}
              elsif z.type == "NS"
                _create_entity "DnsRecord", { :name => z.name.to_s, :type => "NS" }
              else
                _create_entity "DnsRecord", { :name => z.name.to_s, :type => z.type.to_s }
              end
            end
            # Record keeping
            @task_log.good "Zone Tranfer Succeeded on #{domain_name}"
          end
        end

      rescue Timeout::Error
        @task_log.error "Execution Timed out"
      rescue Dnsruby::Refused
        @task_log.error "Zone Transfer against #{domain_name} refused."
      rescue Dnsruby::ResolvError
        @task_log.error "Unable to resolve #{domain_name} while querying #{nameserver}."
      rescue Dnsruby::ResolvTimeout
        @task_log.error "Timed out while querying #{nameserver} for #{domain_name}."
      rescue Exception => e
        @task_log.error "Unknown exception: #{e}"

      end
    end
  end


end
