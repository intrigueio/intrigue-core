module Intrigue
module Task
class DnsBruteSub < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_brute_sub",
      :pretty_name => "DNS Subdomain Bruteforce",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Domain","DnsRecord"],
      :example_entities =>  [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "brute_list", :regex => "alpha_numeric_list", :default =>
          ["mx", "mx1", "mx2", "www", "ww2", "ns1", "ns2", "ns3", "test",
            "mail", "owa", "vpn", "admin", "intranet", "gateway", "secure",
            "admin", "service", "tools", "doc", "docs", "network", "help",
            "en", "sharepoint", "portal", "public", "private", "pub", "zeus",
            "mickey", "time", "web", "it", "my", "photos", "safe", "download",
            "dl", "search", "staging", "fw", "firewall", "email"]  },
        {:name => "use_mashed_domains", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "use_permutations", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_sub.list" },
        {:name => "brute_alphanumeric_size", :type => "Integer", :regex => "integer", :default => 0 },
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 1 },
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # get options
    opt_threads = _get_option("threads")
    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")
    opt_mashed_domains = _get_option("use_mashed_domains")
    opt_use_permutations = _get_option("use_permutations")
    opt_brute_list = _get_option("brute_list")
    opt_brute_alphanumeric_size = _get_option("brute_alphanumeric_size")

    # Set the suffix
    suffix = _get_entity_name

    # Handle cases of *.test.com (pretty common when grabbing
    # DNSRecords from SSLCertificates)
    if suffix[0..1] == "*."
      suffix = suffix[2..-1]
    end

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      _log "Using file: #{opt_filename}"
      subdomain_list = File.read("#{$intrigue_basedir}/data/#{opt_filename}").split("\n")
    else
      _log "Using provided brute list."
      subdomain_list = opt_brute_list
      subdomain_list = subdomain_list.split(",") if subdomain_list.kind_of? String
    end

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    wildcard_ips = _check_wildcard(suffix)

    # Generate alphanumeric list of hostnames and add them to the end of the list
    if opt_brute_alphanumeric_size
      _log "Alphanumeric list generation is pretty huge - this will take a long time" if opt_brute_alphanumeric_size > 3
      subdomain_list.concat(("#{'a' * opt_brute_alphanumeric_size }".."#{'z' * opt_brute_alphanumeric_size}").map {|x| x })
    end

    # Create a queue to hold our list of domains
    work_q = Queue.new

    # Handle mashed domains
    #
    #  See HDM's info on password stealing, try without a dot to see if this
    #  domain has been hijacked by someone - great for finding phishing attempts
    if opt_mashed_domains
      # TODO - more research needed here, are there other common versions of this?
      # Note that this is separate from the other subdomain generation since we
      # don't want to include a "." before the suffix
      ["wwww","www2","www","ww","w"].each do |d|
        work_q.push({:subdomain => "#{d}", :fqdn => "#{d}#{suffix}", :depth => 1})
      end
    end

    # Enqueue our generated subdomains
    subdomain_list.each do |d|
      work_q.push({:subdomain => "#{d}", :fqdn => "#{d}.#{suffix}", :depth => 1})
    end

    # Create a pool of worker threads to work on the queue
    workers = (0...opt_threads).map do
      Thread.new do
        _log "Starting thread"
        begin
          while work_item = work_q.pop(true)
            begin
              fqdn = "#{work_item[:fqdn].chomp}"
              subdomain = "#{work_item[:subdomain].chomp}"
              depth = work_item[:depth]

              # Try to resolve
              resolved_address = _resolve(fqdn)

              if resolved_address # If we resolved, create the right entities

                unless wildcard_ips.include?(resolved_address)
                  _log_good "Resolved address #{resolved_address} for #{fqdn} and it wasn't in our wildcard list."

                  main_entity = _create_entity("DnsRecord", {"name" => fqdn })

                  # Create new host entity
                  resolve(resolved_address).each do |rr|
                    #_log "Creating... #{rr}"
                    if rr["name"].is_ip_address?
                      _log "Skipping IP... #{rr}"
                      # skip this, we'll get it
                      #_create_entity("IpAddress", rr.except!("record_type"), main_entity )
                    else
                      _create_entity("DnsRecord", {"name" => rr["name"]}, main_entity )
                    end
                  end

                  #
                  # This section will add permutations to our list, if the
                  # opt_use_permutations option is set to true (it is, by default).
                  #
                  # This allows us to take items like 'www' and add a check for
                  # www1 and www2, etc
                  #
                  if opt_use_permutations

                    # Create a list of permutations based on this success
                    permutation_list = [
                      "#{subdomain}#{subdomain}",
                      "#{subdomain}-#{subdomain}",
                      "#{subdomain}001",
                      "#{subdomain}01",
                      "#{subdomain}1",
                      "#{subdomain}-1",
                      "#{subdomain}2",
                      "#{subdomain}-3t",
                      "#{subdomain}-city",
                      "#{subdomain}-client",
                      "#{subdomain}-customer",
                      "#{subdomain}-edge",
                      "#{subdomain}-guest",
                      "#{subdomain}-host",
                      "#{subdomain}-mgmt",
                      "#{subdomain}-net",
                      "#{subdomain}-prod",
                      "#{subdomain}-production",
                      "#{subdomain}-rtr",
                      "#{subdomain}-stage",
                      "#{subdomain}-staging",
                      "#{subdomain}-static",
                      "#{subdomain}-tc",
                      "#{subdomain}-temp",
                      "#{subdomain}-test",
                      "#{subdomain}-vpn",
                      "#{subdomain}-wifi",
                      "#{subdomain}-wireless",
                      "#{subdomain}-www"
                    ]

                    # test to first make sure we don't have a subdomain specific wildcard
                    subdomain_wildcard_ips = _check_wildcard(fqdn)

                    # Before we iterate on this subdomain, let's make sure it's not a wildcard
                    if subdomain_wildcard_ips.empty?
                      _log "Adding permutations: #{permutation_list.join(", ")}"
                      permutation_list.each do |p|
                        work_q.push({:subdomain => "#{p}", :fqdn => "#{p}.#{suffix}", :depth => depth+1})
                      end
                    else
                      _log "Avoiding permutations on #{fqdn} because it appears to be a wildcard."
                    end
                  end # end opt_use_permutations
                else
                  _log "Resolved #{resolved_address} for #{fqdn} to a known wildcard."
                end

              end
            end
          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"
  end

  def _resolve(hostname)
    #_log "Trying to resolve #{hostname}"
    resolve_name(hostname)
  end

  # Check for wildcard DNS
  def _check_wildcard(suffix)
    _log "Checking for wildcards on #{suffix}."

    all_discovered_wildcards = []
      # First we look for a single address that won't exist
      10.times do
        random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"
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


end
end
end
