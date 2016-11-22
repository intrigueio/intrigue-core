require 'dnsruby'
module Intrigue
class DnsRecurseSpf < BaseTask

  def self.metadata
    {
      :name => "dns_recurse_spf",
      :pretty_name => "DNS SPF Recursive Lookup",
      :authors => ["@markstanislav","jcran"],
      :description => "DNS SPF Recursive Lookup",
      :references => [ "https://community.rapid7.com/community/infosec/blog/2015/02/23/osint-through-sender-policy-framework-spf-records"],
      :allowed_types => ["DnsRecord"],
      :example_entities => [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" }
      ],
      :created_types => ["DnsRecord", "IpAddress", "Info", "NetBlock" ]
    }
  end

  def run
    super

    opt_resolver = _get_option "resolver"
    dns_name = _get_entity_attribute "name"
    _log "Running SPF lookup on #{dns_name}"

    # Run a lookup on the entity
    lookup_txt_record(opt_resolver, dns_name)
    _log "done!"

  end

  def lookup_txt_record(opt_resolver, dns_name)

    begin

      res = Dnsruby::Resolver.new(
      :nameserver => opt_resolver,
      :search => [],
      :recurse => "true",
      :query_timeout => 5)

      result = res.query(dns_name, Dnsruby::Types.TXT)

      # If we got a success to the query.
      if result
        _log_good "TXT lookup succeeded on #{dns_name}:"
        _log_good "Result:\n=======\n#{result.to_s}======"

        # Make sure there was actually a record
        unless result.answer.count == 0

          # Iterate through each answer
          result.answer.each do |answer|

            if answer.rdata.first =~ /^v=spf1/

              # We have an SPF record, so let's process it
              answer.rdata.first.split(" ").each do |data|

                _log "Processing SPF component: #{data}"

                if data =~ /^v=spf1/
                  next #skip!

                elsif data =~ /^include:.*/
                  spf_data = data.split(":").last
                  _create_entity "DnsRecord", {"name" => spf_data}

                  # RECURSE!
                  lookup_txt_record spf_data

                elsif data =~ /^ip4:.*/
                  range = data.split(":").last

                  if data.include? "/"
                    _create_entity "NetBlock", {"name" => range }
                  else
                    _create_entity "IpAddress", {"name" => range }
                  end
                end
              end

            else  # store everything else as info
              _create_entity "Info", { "name" => "Non-SPF TXT Record for #{dns_name}", "content" => answer.to_s }
            end

          end

          _log "No more records"

        else
          _log "Lookup succeeded, but no records found"
        end
      else
        _log "Lookup failed, no result"
      end

    rescue Dnsruby::Refused
      _log_error "Lookup against #{dns_name} refused"

    rescue Dnsruby::ResolvError
      _log_error "Unable to resolve #{dns_name}"

    rescue Dnsruby::ResolvTimeout
      _log_error "Timed out while querying #{dns_name}."

    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"

    rescue Exception => e
      _log_error "Unknown exception: #{e}"
    end
  end


end
end
