require 'resolv'

class DnsBruteSubTask < BaseTask

  def metadata
    {
      :version => "1.0",
      :name => "dns_brute_sub",
      :pretty_name => "DNS Subdomain Bruteforce",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce",
      :references => [],
      :allowed_types => ["DnsRecord"],
      :example_entities =>   [{:type => "DnsRecord", :attributes => {:name => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "brute_list", :type => "String", :regex => "alpha_numeric_list", :default =>
          ["mx", "mx1", "mx2", "www", "ww2", "ns1", "ns2", "ns3", "test", "mail", "owa", "vpn", "admin", "intranet",
            "gateway", "secure", "admin", "service", "tools", "doc", "docs", "network", "help", "en", "sharepoint", "portal",
            "public", "private", "pub", "zeus", "mickey", "time", "web", "it", "my", "photos", "safe", "download", "dl",
            "search", "staging"
          ]
        },
        {:name => "use_mashed_domains", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "use_permutations", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_sub.list" },

      ],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super
=begin

Some cases to think through:

[ ] : Attempting Zone Transfer on rakuten.ne.jp against nameserver ns01c.rakuten.co.jp
[ ] : Attempting Zone Transfer on soku.com against nameserver ns1.youku.com
[ ] : Attempting Zone Transfer on fh21.com.cn against nameserver ns3.dnsv4.com
[ ] : Attempting Zone Transfer on fanli.com against nameserver ns3.dnsv5.com
[ ] : Attempting Zone Transfer on cookmates.com against nameserver ns1.zkonsult.com
[ ] : Attempting Zone Transfer on yhd.com against nameserver dns1.yihaodian.com
[ ] : Unable to query whois: execution expired
[-] : Domain WHOIS failed, we don't know what nameserver to query.
[+] : Ship it!
[ ] : Writing to file: /home/jcran/topm/core/results/dns_transfer_zone-ted.com.json
2015-03-16T16:03:59.491Z 3775 TID-e9nwc DnsTransferZoneTask JID-4e881cdf1f2601e05665c296 INFO: done: 10.036 sec
2015-03-16T16:03:59.492Z 3775 TID-e9nwc DnsTransferZoneTask JID-a27d255bc26f34dc2b6e3467 INFO: start
[ ] : Task: dns_transfer_zone
[ ] : Id: f95ce029-1ddf-42d0-8ad2-b99bdb52504c
[ ] : Task entity: {"type"=>"DnsRecord", "attributes"=>{"name"=>"adp.com"}}
[ ] : Task options: []
[ ] : Option configured: resolver=8.8.8.8
[ ] : Unable to query whois: execution expired
[-] : Domain WHOIS failed, we don't know what nameserver to query.
[+] : Ship it!
=end

    # get options
    opt_resolver = _get_option "resolver"
    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")
    opt_mashed_domains = _get_option "use_mashed_domains"
    opt_brute_list = _get_option("brute_list")
    opt_use_permutations = _get_option("use_permutations")

    # Set the suffix
    suffix = _get_entity_attribute "name"

    # XXX - use the resolver option if we have it.
    resolver = Resolv.new

    # Handle cases of *.test.com (pretty common when grabbing
    # DNSRecords from SSLCertificates)
    if suffix[0..1] == "*."
      suffix = suffix[2..-1]
    end

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      @task_log.log "Using file #{opt_filename}"
      subdomain_list = File.open("#{$intrigue_basedir}/data/#{opt_filename}","r").read.split("\n")
    else
      @task_log.log "Using provided brute list"
      subdomain_list = opt_brute_list
      subdomain_list = subdomain_list.split(",") if subdomain_list.kind_of? String
    end

    @task_log.good "Using subdomain list: #{subdomain_list}"

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    begin
      if resolver.getaddress("noforkingway#{rand(100000)}.#{suffix}")
        wildcard_domain = true
        @task_log.error "WARNING! Wildcard domain detected, only saving validated domains/hosts."
      end
    rescue Resolv::ResolvError
      @task_log.good "Looks like no wildcard dns. Moving on."
    end

    # Iterate through the subdomain list
    subdomain_list.each do |subdomain|

      subdomain = subdomain.chomp

      begin
        if opt_mashed_domains
          # See HDM's info on password stealing, try without a dot to see if this
          # domain has been hijacked by someone - great for finding phishing attempts
          brute_domain = "#{subdomain}#{suffix}"
        else
          brute_domain = "#{subdomain}.#{suffix}"
        end

        # Try to resolve
        resolved_address = resolver.getaddress(brute_domain)
        @task_log.good "Resolved Address #{resolved_address} for #{brute_domain}" if resolved_address

        # If we resolved, create the right entities
        if (resolved_address && !(wildcard_domain))
          # create new host and domain entities
          _create_entity("DnsRecord", {:name => brute_domain })
          _create_entity("IpAddress", {:name => resolved_address})

          if opt_use_permutations
            # Create a list of permutations based on this success
            permutation_list = ["#{subdomain}1",

            @task_log.log "Adding permutations: #{permutation_list.join(", ")}"

            subdomain_list.concat permutation_list
          end

        end

      rescue Exception => e
        @task_log.error "Hit exception: #{e}"
      end
    end
  end


end
