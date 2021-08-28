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
        {:name => "brute_list", :regex => "alpha_numeric_list", :default => [
            "admin", "admin", "dl", "doc", "docs", "download", "email", "en",
            "firewall", "ftp", "fw", "gateway", "help", "hr", "intranet", "it",
            "mail", "mickey", "mx", "mx1", "mx2", "my", "network", "ns1", "ns2",
            "ns3", "owa", "photos", "portal", "private", "pub", "public", "safe",
            "search", "secure", "service", "sharepoint", "staging", "test", "time",
            "tools", "vpn", "web", "ww2", "www", "zeus" ] },
        {:name => "use_mashed_domains", :regex => "boolean", :default => false },
        {:name => "use_permutations", :regex => "boolean", :default => true },
        {:name => "use_file", :regex => "boolean", :default => false },
        {:name => "brute_file", :regex => "filename", :default => "dns_sub.list" },
        {:name => "brute_alphanumeric_size", :regex => "integer", :default => 0 },
        {:name => "threads", :regex => "integer", :default => 10 },
      ],
      :created_types => ["IpAddress","DnsRecord","Domain"]
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
    wildcards = gather_wildcard_resolutions(suffix)
    unless wildcards.empty?
      _log_error "Unable to continue, this is a wildcard"
      _set_entity_detail "wildcard_brute_error", true
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

    to_check_count = work_q.size
    _log "Checking #{to_check_count} subdomains"

    # Create a pool of worker threads to work on the queue
    start_time = Time.now
    found_count = 0
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

                wildcard_ips = wildcards.map{|x| x["lookup_details"].map{|x| x["response_record_data"]} }.flatten.uniq
                unless wildcard_ips.include?(resolved_address)
                  found_count += 1
                  _log_good "Resolved address #{resolved_address} for #{fqdn}!"

                  # create it!
                  create_dns_entity_from_string fqdn

                  #
                  # This section will add permutations to our list, if the
                  # opt_use_permutations option is set to true (it is, by default).
                  #
                  # This allows us to take items like 'www' and add a check for
                  # www1 and www2, etc
                  #
                  if opt_use_permutations
                    _check_permutations(subdomain,suffix,resolved_address,work_q,depth)
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
    duration = Time.now - start_time

    _log "Stats:"
    _log "Ran for #{duration}"
    _log "Checked #{to_check_count} domains"
    _log "Found #{found_count} domains"

  end

  def _resolve(hostname)
    resolve_name(hostname)
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
      _log_error "Looks like we found a pattern matching DNS server, lets skip permutations on: #{subdomain}.#{suffix}"
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
      "#{subdomain}-dev",
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
      "#{subdomain}-www",
      "#{subdomain}dev",
      "#{subdomain}prod",
      "#{subdomain}staging",
      "#{subdomain}stage",
      "#{subdomain}test",
      "#{subdomain}tst"
    ]

    # test to first make sure we don't have a subdomain specific wildcard
    subdomain_wildcards = gather_wildcard_resolutions("#{subdomain}.#{suffix}").uniq

    # Before we iterate on this subdomain, let's make sure it's not a wildcard
    if subdomain_wildcards.empty?
      _log "Adding permutations: #{permutation_list.join(", ")}"
      permutation_list.each do |p|
        queue.push({:subdomain => "#{p}", :fqdn => "#{p}.#{suffix}", :depth => depth+1})
      end
    else
      _log "Avoiding permutations on #{p}.#{suffix} because it appears to be a wildcard."
    end
  end

end
end
end
