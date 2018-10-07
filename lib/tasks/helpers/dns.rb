module Intrigue
  module Task
    module Dns

      include Intrigue::Task::Generic

      def resolve_ips(lookup_name, lookup_types=[Dnsruby::Types::PTR])
        resolve_names(lookup_name,lookup_types)
      end

      # convenience method to just send back name
      def resolve_name(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME])
        resolve_names(lookup_name,lookup_types).first
      end

      # convenience method to just send back names
      def resolve_names(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME])

        names = []
        x = resolve(lookup_name, lookup_types)
        x.each {|y| names << y["name"] }

      names.uniq
      end

      def resolve(lookup_name, lookup_types=[Dnsruby::Types::A, Dnsruby::Types::CNAME])

        resolver_name = _get_system_config "resolver"

        begin
          resolver = Dnsruby::Resolver.new(
            :search => [],
            :nameserver => [resolver_name],
            :query_timeout => 3
          )

          results = []
          lookup_types.each do |t|
            begin
              #_log "Attempting lookup on #{lookup_name} with type #{t}"
              results << resolver.query(lookup_name, t)
            rescue Dnsruby::NXDomain => e
              _log_error "Unable to resolve: #{lookup_name}, no such domain: #{e}"
            rescue Dnsruby::SocketEofResolvError => e
              _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
            rescue Dnsruby::ServFail => e
              _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
            rescue Dnsruby::ResolvTimeout => e
              _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
            end
          end

          # For each of the found addresses
          resources = []
          results.each do |result|

            # Let us know if we got an empty result
            next if result.answer.empty?

            result.answer.map do |resource|

              next if resource.type == Dnsruby::Types::NS

              resources << {
                "name" => resource.address.to_s,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata.to_s,
                  "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :address

              resources << {
                "name" => resource.domainname.to_s.downcase,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata,
                  "nameservers" => resolver.config.nameserver }]} if resource.respond_to? :domainname

              resources << {
                "name" => resource.name.to_s.downcase,
                "lookup_details" => [{
                  "request_record" => lookup_name,
                  "response_record_type" => resource.type.to_s,
                  "response_record_data" => resource.rdata,
                  "nameservers" => resolver.config.nameserver }]}

            end # end result.answer
          end
        rescue Dnsruby::SocketEofResolvError => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ServFail => e
          _log_error "Unable to resolve: #{lookup_name}, error: #{e}"
        rescue Dnsruby::ResolvTimeout => e
          _log_error "Unable to resolve: #{lookup_name}, timed out: #{e}"
        rescue Errno::ENETUNREACH => e
          _log_error "Hit exception: #{e}. Are you sure you're connected?"
        end

      resources || []
      end


      def collect_soa_details(lookup_name)
        _log "Checking start of authority"
        response = resolve(lookup_name, [Dnsruby::Types::SOA])

        # Check for sanity
        skip = true unless response &&
                           !response.empty? &&
                           response.first["lookup_details"].first["response_record_type"] == "SOA"

        unless skip
          data = response.first["lookup_details"].first["response_record_data"]

          # https://support.dnsimple.com/articles/soa-record/
          # [0] primary name server
          # [1] responsible party for the domain
          # [2] timestamp that changes whenever you update your domain
          # [3] number of seconds before the zone should be refreshed
          # [4] number of seconds before a failed refresh should be retried
          # [5] upper limit in seconds before a zone is considered no longer authoritative
          # [6]  negative result TTL

          soa = {
            "primary_name_server" => "#{data[0]}",
            "responsible_party" => "#{data[1]}",
            "timestamp" => data[2],
            "refresh_after" => data[3],
            "retry_refresh_after" => data[4],
            "nonauthoritative_after" => data[5],
            "retry_fail_after" => data[6]
          }

        else
          soa = false
        end
      soa
      end

      def collect_mx_records(lookup_name)
        _log "Collecting MX records"
        response = resolve(lookup_name, [Dnsruby::Types::MX])
        skip = true unless response && !response.empty?

        mx_records = []
        unless skip
          response.each do |r|
            r["lookup_details"].each do |record|
              next unless record["response_record_type"] == "MX"
              mx_records << {
                "priority" => record["response_record_data"].first,
                "host" => "#{record["response_record_data"].last}" }
            end
          end
        end

      mx_records
      end

      def collect_spf_details(lookup_name)
        _log "Collecting SPF records"
        response = resolve(lookup_name, [Dnsruby::Types::TXT])
        skip = true unless response && !response.empty?

        spf_records = []
        unless skip
          response.each do |r|
            r["lookup_details"].each do |record|
              next unless record["response_record_type"] == "TXT"
              next unless record["response_record_data"].first =~ /spf/i
              spf_records << record["response_record_data"].first
            end
          end
        end

      spf_records
      end

      def collect_txt_records(lookup_name)
        _log "Collecting TXT records"
        response = resolve(lookup_name, [Dnsruby::Types::TXT])
        skip = true unless response && !response.empty?

        txt_records = []
        unless skip
          response.each do |r|
            r["lookup_details"].each do |record|
              next unless record["response_record_type"] == "TXT"
              txt_records << record["response_record_data"].first
            end
          end
        end

      txt_records
      end

      def collect_whois_data(lookup_name)
          _log "Collecting Whois record"
          whois(lookup_name)
      end

      def collect_resolutions(results)
        ####
        ### Set details for this entity
        ####
        dns_entries = []
        results.each do |result|

          # skip anything without a lookup
          next unless result["lookup_details"]

          # Clean up the response and make it serializable
          xtype = result["lookup_details"].first["response_record_type"].to_s.sanitize_unicode
          lookup_details = result["lookup_details"].first["response_record_data"]
          if lookup_details.kind_of?(Dnsruby::IPv4) || lookup_details.kind_of?(Dnsruby::IPv6) || lookup_details.kind_of?(Dnsruby::Name)
            _log "Sanitizing Dnsruby Object"
            xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
          else
            _log "Sanitizing String or Array"
            xdata = result["lookup_details"].first["response_record_data"].to_s.sanitize_unicode
          end
          dns_entries << { "response_data" => xdata, "response_type" => xtype }
        end

      dns_entries.uniq
      end

    end
  end
end
