require 'resolv'
require 'thread'
require 'eventmachine'
require 'resolv-replace'

module Intrigue
class DnsBruteSubTask < BaseTask

  def self.metadata
    {
      :name => "dns_brute_sub",
      :pretty_name => "DNS Subdomain Bruteforce",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["DnsRecord","String"],
      :example_entities =>  [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "brute_list", :type => "String", :regex => "alpha_numeric_list", :default =>
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
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 3 },
      ],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super

    # get options
    opt_resolver = _get_option("resolver")
    opt_threads = _get_option("threads")
    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")
    opt_mashed_domains = _get_option("use_mashed_domains")
    opt_use_permutations = _get_option("use_permutations")
    opt_brute_list = _get_option("brute_list")
    opt_brute_alphanumeric_size = _get_option("brute_alphanumeric_size")

    # Set the suffix
    suffix = _get_entity_name

    # XXX - use the resolver option if we have it.
    # Note that we have to specify an empty search list, otherwise we end up
    # searching .local by default on osx.
    @resolver = Resolv.new([Resolv::DNS.new(:nameserver => opt_resolver,:search => [])])

    # Handle cases of *.test.com (pretty common when grabbing
    # DNSRecords from SSLCertificates)
    if suffix[0..1] == "*."
      suffix = suffix[2..-1]
    end

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      _log "Using file: #{opt_filename}"
      subdomain_list = File.open("#{$intrigue_basedir}/data/#{opt_filename}","r").read.split("\n")
    else
      _log "Using provided brute list"
      subdomain_list = opt_brute_list
      subdomain_list = subdomain_list.split(",") if subdomain_list.kind_of? String
    end

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    wildcard_ips = _check_wildcard(suffix)
    #unless wildcard_ips.empty?
      # Go ahead and log this, since we'll want to tell the user what's happening.
    #  wildcard_ips.sort.uniq.each {|i| _create_entity "IpAddress", "name" => "#{i}" }
    #end

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
      ["www","ww","w"].each do |d|
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
        begin
          while work_item = work_q.pop(true)
            begin
              fqdn = "#{work_item[:fqdn].chomp}"
              subdomain = "#{work_item[:subdomain].chomp}"
              depth = work_item[:depth]

              # Prevent us from going down a hole (some subdomains will resolve anything under them)
              if depth > 3
                _log_error "Got too deep, returning!"
                return
              end

              # Try to resolve
              resolved_address = _resolve(fqdn)
              if resolved_address # If we resolved, create the right entities

                unless wildcard_ips.include?(resolved_address)
                  _log_good "Resolved address #{resolved_address} for #{fqdn} and it wasn't in our wildcard list."

                  # Create new host and domain entities
                  _create_entity("DnsRecord", {"name" => "#{fqdn}", "ip_address" => "#{resolved_address}" })
                  #_create_entity("IpAddress", {"name" => "#{resolved_address}", "dns_record" => "#{fqdn}" })

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
                  _log "Resolved address #{resolved_address} for #{fqdn} but it resolved to a known wildcard."
                end

              end
            rescue Errno::ENETUNREACH => e
              _log_error "Hit exception: #{e}. Are you sure you're connected?"
            rescue Resolv::ResolvError => e
              _log "No resolution for: #{fqdn}"
            end
          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"
  end

  def _resolve(hostname)
    begin
      x = @resolver.getaddress(hostname)
    rescue Errno::ENETUNREACH => e
      _log_error "Hit exception: #{e}. Are you sure you're connected?"
    rescue Resolv::ResolvError => e
      _log "Unable to resolve: #{e}."
    end
  x
  end

  # Check for wildcard DNS
  def _check_wildcard(suffix)
    _log "Checking for wildcards on #{suffix}."

    wildcard_ips = []
      # First we look for a single address that won't exist
      5.times do
        random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"
        resolved_address = _resolve(random_string)
        wildcard_ips << resolved_address unless resolved_address.nil?
      end

      # If that resolved, we know that we're in a wildcard situation.
      #
      # Some domains have a pool of IPs that they'll resolve to, so
      # let's go ahead and test a bunch of different domains to try
      # and collect those IPs. This number (250) is somewhat
      # arbitrarily chosen but seems to generally work in practice.
      if wildcard_ips.uniq.count > 1
        _log "Multiple wildcard ips for #{suffix} after resolving these: #{wildcard_ips}."
        _log "Trying to create an exhaustive list."

        # Now we have to test for things that return a block of addresses as a wildcard.
        # 300 is hardcoded here, but we may want to consider something adaptive (to a point)
        300.times do |x|
          random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"
          resolved_address = _resolve(random_string)
          wildcard_ips << resolved_address unless resolved_address.nil?
        end

        _log "Got these wildcard ips: #{wildcard_ips.sort.uniq}"
      elsif wildcard_ips.uniq.count == 1
        _log "Only a single wildcard ip: #{wildcard_ips.sort.uniq}"
      else
        _log "No wildcard detected! Moving on!"
      end

  wildcard_ips.uniq # if it's not a wildcard, this will be an empty array.
  end


end
end
