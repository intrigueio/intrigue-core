#require 'dnsruby'

module Intrigue
module Task
class DnsBruteSubAsync < BaseTask

  include Intrigue::Task::Dns

  RESOLVER = Dnsruby::Resolver.new(:nameserver => %w(8.8.8.8  8.8.4.4))

  # Experiment with this to get fast throughput but not overload the dnsruby async mechanism:
  #RESOLVE_CHUNK_SIZE = 50

  def self.metadata
    {
      :name => "dns_brute_sub_async",
      :pretty_name => "DNS Subdomain Bruteforce (Async)",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce (Async)",
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
        #{:name => "use_permutations", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_sub.list" },
        {:name => "brute_alphanumeric_size", :type => "Integer", :regex => "integer", :default => 0 },
        {:name => "records_per_request", :type => "Integer", :regex => "integer", :default => 50 },
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
    opt_records_per_request = _get_option("records_per_request")

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
      _log "Checking #{subdomain_list.count} subdomains"
    else
      _log "Using provided brute list."
      subdomain_list = opt_brute_list
      subdomain_list = subdomain_list.split(",") if subdomain_list.kind_of? String
    end

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    wildcard_ips = _check_wildcard(suffix)

    unless wildcard_ips
      _log_error "Unable to continue, we can't verify wildcard status"
      @entity.set_detail "wildcard_brute_error", true
      return
    end

    # Generate alphanumeric list of hostnames and add them to the end of the list
    if opt_brute_alphanumeric_size

      _log "Alphanumeric list generation is pretty huge - this will take a long time" if opt_brute_alphanumeric_size > 3

      if opt_brute_alphanumeric_size >=5
        _log "Capping alphanumeric list at size 5"
        opt_brute_alphanumeric_size = 5
      end

      subdomain_list.concat(("#{'a' * opt_brute_alphanumeric_size }".."#{'z' * opt_brute_alphanumeric_size}").map {|x| x })
    end

    # Enqueue our generated subdomains
    fqdn_list = subdomain_list.map { |d| "#{d}.#{suffix}"}

    _log "Checking #{fqdn_list.count} subdomains"

    start_time = Time.now
    ip_entries = fqdn_list.each_slice(opt_records_per_request).each_with_object([]) do |ip_entries_chunk, results|
      _log "Working on slice starting with... #{ip_entries_chunk.first}"
      results.concat get_ip_entries(ip_entries_chunk)
    end

    found, not_found = ip_entries.partition { |entry| entry.ip }

    # create entities
    found.each do |f|

      unless wildcard_ips.include?(f.ip)
        dns_entity = _create_entity("DnsRecord", {"name" => f.name })
        _create_entity("IpAddress", {"name" => f.ip }, dns_entity)
      else
        _log "Resolved #{f.name} to a known wildcard: #{f.ip}"
      end

      #if opt_use_permutations
      #  _check_permutations(subdomain,suffix,resolved_address,work_q,depth)
      #end # end opt_use_permutations

    end

    duration = Time.now - start_time

    stats = {
        duration:        duration,
        domain_count:    ip_entries.size,
        found_count:     found.size,
        not_found_count: not_found.size,
    }
    _log "Stats:\n: #{stats}"
  end

  IpEntry = Struct.new(:name, :ip) do
    def to_s
      "#{name}: #{ip ? ip : '(nil)'}"
    end
  end


  def _check_permutations(subdomain,suffix,resolved_address,queue,depth)
    # first check to make sure that it's not just simple pattern matching.
    #
    # for example... if we get webfarm, check that
    # webfarm-anythingcouldhappen123213213.whitehouse.gov doesnt
    # exist.
    # "#{subdomain}-anythingcouldhappen#{rand(100000000)}"
    # TODO - keep track of this address and add anything
    # that's not it, like our wildcard checking!
    original_address = _resolve(resolved_address)
    invalid_name = "#{subdomain}-nowaythisexists#{rand(10000000000)}.#{suffix}"
    invalid_address = _resolve(invalid_name)
    _log "Checking invalid permutation: #{invalid_name}"

    if invalid_address == original_address
      _log_error "Looks like we found a pattern matching DNS server, lets skip this: #{subdomain}.#{suffix}"
      return
    else
      _log_good "Looks like we are not pattern matching, continuing on with permutation checking!"
    end

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
    subdomain_wildcard_ips = _check_wildcard("#{subdomain}.#{suffix}")

    # Before we iterate on this subdomain, let's make sure it's not a wildcard
    if subdomain_wildcard_ips.empty?
      _log "Adding permutations: #{permutation_list.join(", ")}"
      permutation_list.each do |p|
        queue.push({:subdomain => "#{p}", :fqdn => "#{p}.#{suffix}", :depth => depth+1})
        to_check_count+=1
      end
    else
      _log "Avoiding permutations on #{fqdn} because it appears to be a wildcard."
    end
  end


  def assemble_subdomains(subdomain_prefixes, domains)
    domains.each_with_object([]) do |domain, subdomains|
      subdomain_prefixes.each do |prefix|
        subdomains << "#{prefix}.#{domain}"
      end
    end
  end


  def create_query_message(name)
    Dnsruby::Message.new(name, 'A')
  end


  def parse_response_for_address(response)
    begin
      a_answer = response.answer.detect { |a| a.type == 'A' }
      a_answer ? a_answer.rdata.to_s : nil
    rescue NoMethodError => e
      _log_error "Error: #{e}"
      _log_error "Response: #{response}"
    rescue Dnsruby::NXDomain
      return nil
    end
  end

  def get_ip_entries(names)

    queue = Queue.new

    names.each do |name|
      query_message = create_query_message(name)
      RESOLVER.send_async(query_message, queue, name)
    end


    # Note: although map is used here, the record in the output array will not necessarily correspond
    # to the record in the input array, since the order of the messages returned is not guaranteed.
    # This is indicated by the lack of block variable specified (normally w/map you would use the element).
    # That should not matter to us though.
    names.map do
      _id, result, error = queue.pop
      name = _id
      case error
        when Dnsruby::NXDomain
          #_log_error "Timed out on: #{_id}"
          IpEntry.new(name, nil)
        when Dnsruby::ResolvTimeout
          _log_error "Timed out on: #{_id}"
          IpEntry.new(name, nil)
        when NilClass
         ip = parse_response_for_address(result)
         IpEntry.new(name, ip)
        else
         raise error
        end
    end
  end

  def _resolve(hostname)
    resolve_name(hostname,[Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME])
  end

  # Check for wildcard DNS
  def _check_wildcard(suffix)
    _log "Checking for wildcards on #{suffix}."

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

    # Now check for wildcards
    all_discovered_wildcards = []
    10.times do
      random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{suffix}"

      # do the resolution
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
