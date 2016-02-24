require 'resolv'
require 'thread'
require 'eventmachine'
require 'resolv-replace'

module Intrigue
class DnsBruteSubTask < BaseTask

  def metadata
    {
      :name => "dns_brute_sub",
      :pretty_name => "DNS Subdomain Bruteforce",
      :authors => ["jcran"],
      :description => "DNS Subdomain Bruteforce",
      :references => [],
      :allowed_types => ["DnsRecord","String"],
      :example_entities =>   [{"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}],
      :allowed_options => [
        {:name => "resolver", :type => "String", :regex => "ip_address", :default => "8.8.8.8" },
        {:name => "brute_list", :type => "String", :regex => "alpha_numeric_list", :default =>
          ["mx", "mx1", "mx2", "www", "ww2", "ns1", "ns2", "ns3", "test", "mail", "owa", "vpn", "admin", "intranet",
            "gateway", "secure", "admin", "service", "tools", "doc", "docs", "network", "help", "en", "sharepoint", "portal",
            "public", "private", "pub", "zeus", "mickey", "time", "web", "it", "my", "photos", "safe", "download", "dl",
            "search", "staging"
          ]
        },
        #{:name => "use_mashed_domains", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "use_permutations", :type => "Boolean", :regex => "boolean", :default => true },
        {:name => "use_file", :type => "Boolean", :regex => "boolean", :default => false },
        {:name => "brute_file", :type => "String", :regex => "filename", :default => "dns_sub.list" },
        {:name => "brute_alphanumeric_size", :type => "Integer", :regex => "integer", :default => 0 },
        {:name => "threads", :type => "Integer", :regex => "integer", :default => 1 },
      ],
      :created_types => ["DnsRecord","IpAddress"]
    }
  end

  def run
    super

    # get options
    opt_resolver = _get_option "resolver"
    opt_threads = _get_option("threads")
    opt_use_file = _get_option("use_file")
    opt_filename = _get_option("brute_file")
    #opt_mashed_domains = _get_option "use_mashed_domains"
    opt_use_permutations = _get_option("use_permutations")
    opt_brute_list = _get_option("brute_list")
    opt_brute_alphanumeric_size = _get_option("brute_alphanumeric_size")

    # Set the suffix
    suffix = _get_entity_attribute "name"

    # XXX - use the resolver option if we have it.
    # Note that we have to specify an empty search list, otherwise we end up
    # searching .local by default on osx.
    resolver = Resolv.new([Resolv::DNS.new(:nameserver => opt_resolver,:search => [])])

    # Handle cases of *.test.com (pretty common when grabbing
    # DNSRecords from SSLCertificates)
    if suffix[0..1] == "*."
      suffix = suffix[2..-1]
    end

    # Create the brute list (from a file, or a provided list)
    if opt_use_file
      @task_result.logger.log "Using file #{opt_filename}"
      subdomain_list = File.open("#{$intrigue_basedir}/data/#{opt_filename}","r").read.split("\n")
    else
      @task_result.logger.log "Using provided brute list"
      subdomain_list = opt_brute_list
      subdomain_list = subdomain_list.split(",") if subdomain_list.kind_of? String
    end

    @task_result.logger.log_good "Using subdomain list: #{subdomain_list}"

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)
    begin
      wildcard = resolver.getaddress("noforkingway#{rand(100000)}.#{suffix}")
      if wildcard
        _create_entity "IpAddress", "name" => "#{wildcard}"
        wildcard_domain = true
        @task_result.logger.log_warning "Wildcard domain detected, only saving validated domains/hosts."
      end
    rescue Resolv::ResolvError
      @task_result.logger.log_good "Looks like no wildcard dns. Moving on."
    end

    # Generate alphanumeric list of hostnames and add them to the end of the list
    if opt_brute_alphanumeric_size
      @task_result.logger.log_warning "Alphanumeric list generation is pretty huge - this will take a long time" if opt_brute_alphanumeric_size > 3
      subdomain_list.concat(("#{'a' * opt_brute_alphanumeric_size }".."#{'z' * opt_brute_alphanumeric_size}").map {|x| x })
    end

    #if opt_mashed_domains
      # See HDM's info on password stealing, try without a dot to see if this
      # domain has been hijacked by someone - great for finding phishing attempts
    #  subdomain_list.concat subdomain_list.map {|x| x.sub(".","")}
    #end

    work_q = Queue.new
    subdomain_list.each{|x| work_q.push x }
    workers = (0...opt_threads).map do
      Thread.new do
        begin
          while subdomain = work_q.pop(true).chomp
            # Do the actual lookup work
            begin
              # Generate the domain
              brute_domain = "#{subdomain}.#{suffix}"

              # Try to resolve
              resolved_address = resolver.getaddress(brute_domain)
              @task_result.logger.log_good "Resolved Address #{resolved_address} for #{brute_domain}" if resolved_address

              # If we resolved, create the right entities
              if (resolved_address && !(wildcard_domain))

                # Create new host and domain entities
                _create_entity("DnsRecord", {"name" => brute_domain })
                _create_entity("IpAddress", {"name" => resolved_address})

                #
                # This section will add permutations to our list, if the
                # opt_use_permutations option is set to true (it is, by default).
                #
                # This allows us to take items like 'www' and add a check for
                # www1 and www2, etc
                #
                if opt_use_permutations
                  # Create a list of permutations based on this success
                  permutation_list = ["#{subdomain}1", "#{subdomain}2", "#{subdomain}-staging","#{subdomain}-prod", "#{subdomain}-stage", "#{subdomain}-test", "#{subdomain}-dev"]
                  @task_result.logger.log "Adding permutations: #{permutation_list.join(", ")}"
                  subdomain_list.concat permutation_list
                end

              end
            rescue Resolv::ResolvError => e
              @task_result.logger.log "No resolution for: #{brute_domain}"
            #rescue Exception => e
            #  @task_result.logger.log_error "Hit exception: #{e.class}: #{e}"
            end
          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

    # Iterate through the subdomain list
    #subdomain_list.each do |subdomain|
    #end
  end


end
end
