require 'flareon'

module Intrigue
module Task
class DnsBruteSubOverHttp < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_brute_sub_over_http",
      :pretty_name => "DNS Subdomain Bruteforce (over HTTP)",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce (over HTTP)",
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
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_sub.list" },
        {:name => "brute_alphanumeric_size", :type => "Integer", :regex => "integer", :default => 0 },
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 5 }
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

    # always check the base domain
    subdomain_list << "#{suffix}"

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    wildcard_ips = check_wildcard(suffix)

    if wildcard_ips
      _log "Known wildcards: #{wildcard_ips}"
    else
      _log_error "Unable to continue, we can't verify wildcard status"
      @entity.set_detail "wildcard_brute_error", true
      return
    end

    # Generate alphanumeric list of hostnames and add them to the end of the list
    if opt_brute_alphanumeric_size

      _log "Alphanumeric list generation is pretty huge - this will take a long time" if opt_brute_alphanumeric_size > 3

      if opt_brute_alphanumeric_size > 5
        _log "Capping alphanumeric list at size 5"
        opt_brute_alphanumeric_size = 5
      end

      subdomain_list.concat(("#{'a' * opt_brute_alphanumeric_size }".."#{'z' * opt_brute_alphanumeric_size}").map {|x| x })
    end

    # Enqueue our generated subdomains
    fqdn_list = subdomain_list.map { |d| "#{d}.#{suffix}"}

    _log "Checking #{fqdn_list.count} subdomains"

    start_time = Time.now

    # resolve using flareon
    results = Flareon.batch_query_multithreaded(fqdn_list, threads: opt_threads)
    duration = Time.now - start_time

    # create entities
    results.each do |r|
      unless wildcard_ips.include?(r["Answer"].first["data"])
        dns_entity = _create_entity("DnsRecord", {"name" => r["Question"].first["name"] })
        _create_entity("IpAddress", {"name" => r["Answer"].first["data"] }, dns_entity)
      else
        _log "Resolved #{f.name} to a known wildcard: #{f.ip}"
      end

    end

    stats = {
        duration:        duration,
        domain_count:    fqdn_list.count,
        found_count:     results.count
    }
    _log "Stats:\n: #{stats}"
  end

  def _resolve(hostname)
    resolve_name(hostname,[Dnsruby::Types::AAAA, Dnsruby::Types::A, Dnsruby::Types::CNAME])
  end

end
end
end
