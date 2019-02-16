module Intrigue
  module Task
    module Dns

      include Intrigue::Task::Generic

      def check_resolv_sanity(lookup_name)

        config = {
          :search => [],
          :retry_times => 3,
          :retry_delay => 3,
          :packet_timeout => 10,
          :query_timeout => 30
        }

        if _get_system_config("resolvers")
          config[:nameserver] = _get_system_config("resolvers").split(",")
        end

        resolver = Dnsruby::Resolver.new(config)

        begin
          resolver.query(lookup_name)
        rescue Dnsruby::NXDomain => e
          return false
        rescue IOError => e
          _log_error "Unable to resolve, ioerror: #{e}"
          return true
        rescue Dnsruby::SocketEofResolvError => e
          _log_error "Unable to resolve, server failure: #{e}"
          return true
        rescue Dnsruby::ServFail => e
          _log_error "Unable to resolve, server failure: #{e}"
          return true
        rescue Dnsruby::ResolvTimeout => e
          _log_error "Timed out"
          return true
        end

      false
      end

      # Check for wildcard DNS
      def check_wildcard(suffix)
        _log "Checking for wildcards on #{suffix}."
        all_discovered_wildcards = []

        # First check if we can even get a reliable result
        timeout_count = 0
        10.times do
          random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"

          # keep track of timeouts
          _log "Checking: #{random_string}"
          timeout_count += 1 if check_resolv_sanity random_string
        end

        # fail if most timed out
        if timeout_count > 5
          _log_error "More than 50% of our wildcard checks timed out, cowardly refusing to continue"
          return nil
        end

        # first, check wordpress....
        # www*
        # ww01*
        # web*
        # home*
        # my*
        check_wordpress_list = []
        ["www.doesntexist.#{suffix}","ww01.#{suffix}","web1.#{suffix}","hometeam.#{suffix}","myc.#{suffix}"].each do |d|
          resolved_address = _resolve(d)
          check_wordpress_list << resolved_address
          #unless resolved_address.nil? || all_discovered_wildcards.include?(resolved_address)
          #  all_discovered_wildcards << resolved_address
          #end
        end

        if check_wordpress_list.compact.count == 5
          _log "Looks like  wordpress-connected domain"
          all_discovered_wildcards = check_wordpress_list
        end

        # Now check for wildcards
        10.times do
          random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"

          # do the resolution
          # www.shopping.intrigue.io - 198.105.244.228
          # www.search.intrigue.io - 198.105.254.228
          resolved_address = _resolve(random_string)

          # keep track of it unless we already have it
          unless resolved_address.nil? || all_discovered_wildcards.include?(resolved_address)
            all_discovered_wildcards << resolved_address
          end

        end

        # If that resolved, we know that we're in a wildcard situation.
        #
        # Some domains have a pool of IPs that they'll resolve to, so
        # let's go ahead and test a bunch of different domains to try
        # and collect those IPs
        if all_discovered_wildcards.uniq.count > 1
          _log "Multiple wildcard ips for #{suffix} after resolving these: #{all_discovered_wildcards}."
          _log "Trying to create an exhaustive list."

          # Now we have to test for things that return a block of addresses as a wildcard.
          # we to be adaptive (to a point), so let's keep looking in chuncks until we find
          # no new ones...
          no_new_wildcards = false

          until no_new_wildcards
            _log "Testing #{all_discovered_wildcards.count * 20} new entries..."
            newly_discovered_wildcards = []

            (all_discovered_wildcards.count * 20).times do |x|
              random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"
              resolved_address = _resolve(random_string)

              # keep track of it unless we already have it
              unless resolved_address.nil? || newly_discovered_wildcards.include?(resolved_address)
                newly_discovered_wildcards << resolved_address
              end
            end

            # check if our newly discovered is a subset of all
            if (newly_discovered_wildcards - all_discovered_wildcards).empty?
              _log "Hurray! No new wildcards in #{newly_discovered_wildcards}. Finishing up!"
              no_new_wildcards = true
            else
              _log "Continuing to search, found: #{(newly_discovered_wildcards - all_discovered_wildcards).count} new results."
              all_discovered_wildcards += newly_discovered_wildcards.uniq
            end

            _log "Known wildcard count: #{all_discovered_wildcards.uniq.count}"
            _log "Known wildcards: #{all_discovered_wildcards.uniq}"
          end

        elsif all_discovered_wildcards.uniq.count == 1
          _log "Only a single wildcard ip: #{all_discovered_wildcards.sort.uniq}"
        else
          _log "No wildcard detected! Moving on!"
        end

      all_discovered_wildcards.uniq # if it's not a wildcard, this will be an empty array.
      end


      # convenience method to just send back name
      def resolve_name(lookup_name, lookup_types=[Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])
        resolve_names(lookup_name,lookup_types).first
      end

      # convenience method to just send back names
      def resolve_names(lookup_name, lookup_types=[Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])

        names = []
        x = resolve(lookup_name, lookup_types)
        x.each {|y| names << y["name"] }

      names.uniq
      end

      def resolve(lookup_name, lookup_types=[Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME, Dnsruby::Types::PTR])

        config = {
          :search => [],
          :retry_times => 3,
          :retry_delay => 3,
          :packet_timeout => 10,
          :query_timeout => 30
        }

        if _get_system_config("resolvers")
          config[:nameserver] = _get_system_config("resolvers").split(",")
        end

        resolver = Dnsruby::Resolver.new(config)

        results = []
        lookup_types.each do |t|

          begin
            results << resolver.query(lookup_name, t)
          rescue Dnsruby::NXDomain => e
            # silently move on
          rescue IOError => e
            _log_error "Error resolving: #{lookup_name}, error: #{e}"
          rescue Dnsruby::SocketEofResolvError => e
            _log_error "Error resolving: #{lookup_name}, error: #{e}"
          rescue Dnsruby::ServFail => e
            _log_error "Error resolving: #{lookup_name}, error: #{e}"
          rescue Dnsruby::ResolvTimeout => e
            _log_error "Error resolving: #{lookup_name}, error: #{e}"
          end
        end

        return [] if results.empty?

        begin

          # For each of the found addresses
          resources = []
          results.each do |result|

            # Let us know if we got an empty result
            next if result.answer.empty?

            result.answer.map do |resource|

              #next if resource.type == Dnsruby::Types::NS

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

        soa = nil
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

      def check_and_create_unscoped_domain(lookup_name)
        # handy in general, do this for all TLDs
        #if _get_entity_detail("soa_record")
        #  _log_good "Creating domain: #{_get_entity_name}"
        #  _create_entity "Domain", "name" => _get_entity_name
        # one at a time, check all known TLDs and see what we have left. if we
        # have a single string, this is TLD and we should create it as a domain
        begin
          suffix_list = File.open("#{$intrigue_basedir}/data/public_suffix_list.clean.txt").read.split("\n")
        rescue Errno::ENOENT => e
          _log_error "Unable to locate public suffix list, failing to check / create domain for #{lookup_name}"
          return nil
        end

        clean_suffix_list = suffix_list.map{|l| "#{l.downcase}".chomp }

        # for each TLD suffix
        clean_suffix_list.each do |l|
          entity_name = "#{lookup_name}".downcase # TODO - downcase necessary?
          suffix = "#{l.chomp}".downcase
          # determine if there's a match with this suffix
          if entity_name =~ /\.#{suffix}$/
            # if so, remove it
            remove_length = ".#{suffix}".length
            x = entity_name[0..-remove_length]
            if x.split(".").length == 1

              _log "Yahtzee, we are a TLD: #{entity_name}!"

              # since we are creating an identical domain, send up the details
              e = _create_entity "Domain", {
                "name" => "#{lookup_name}",
                "unscoped" => true,
                "resolutions" => _get_entity_detail("resolutions"),
                "soa_record" => _get_entity_detail("soa_record"),
                "mx_records" => _get_entity_detail("mx_records"),
                "txt_records" => _get_entity_detail("txt_records"),
                "spf_record" => _get_entity_detail("spf_record")}

            elsif x.last == "." # clean
              inferred_tld = "#{x.split(".").last}.#{suffix}"
              _log "Inferred TLD: #{inferred_tld}"

              # make sure we don't accidentially create another TLD (co.uk)
              next if clean_suffix_list.include? inferred_tld

              e = _create_entity "Domain", {
                "name" => "#{inferred_tld}",
                "unscoped" => true
              }
            else
              _log "Subtracting suffix (#{suffix}) doesnt make this a tld, moving on."
            end
          end
        end
      end

    end
  end
end
