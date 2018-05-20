module Intrigue
module Task
class DnsPermute < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_permute",
      :pretty_name => "DNS Permute",
      :authors => ["jcran"],
      :description => "Given a DnsRecord, find others that are like it",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["DnsRecord"],
      :example_entities =>  [{"type" => "DnsRecord", "details" => {"name" => "intrigue.io"}}],
      :allowed_options => [],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Set the basename
    basename = _get_entity_name
    
    # XXX - use the resolver option if we have it.
    # Note that we have to specify an empty search list, otherwise we end up
    # searching .local by default on osx.
    @resolver = Resolv.new([Resolv::DNS.new(:search => [])])

    # figure out all of our permutation points here.
    # "google.com" < 1 permutation point?
    # "1.yahoo.com"  < 2 permutation points?
    # "1.test.2.yahoo.com" < 3 permutation points?
    # "1.2.3.4.yahoo.com" < 5 permutation points?
    baselist = basename.split(".")
    brute_domain = baselist[1..-1].join(".")

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)

    wildcard_ips = _check_wildcard(brute_domain)

    # Create a queue to hold our list of attempts
    work_q = Queue.new

    perm_list = [
      { :type => "both", :permutation => "0" },
      { :type => "both", :permutation => "1" },
      { :type => "both", :permutation => "2" },
      { :type => "both", :permutation => "3" },
      { :type => "both", :permutation => "4" },
      { :type => "both", :permutation => "5" },
      { :type => "both", :permutation => "6" },
      { :type => "both", :permutation => "7" },
      { :type => "both", :permutation => "8" },
      { :type => "both", :permutation => "9" },
      { :type => "both", :permutation => "w" },
      { :type => "prefix", :permutation => "www" },
      { :type => "prefix", :permutation => "x" },
      { :type => "suffix", :permutation => "-dev" },
      { :type => "suffix", :permutation => "-prd" },
      { :type => "suffix", :permutation => "-prod" },
      { :type => "suffix", :permutation => "-production" },
      { :type => "suffix", :permutation => "-stg" },
      { :type => "suffix", :permutation => "-stage" },
      { :type => "suffix", :permutation => "-staging" },
      { :type => "suffix", :permutation => "-test" }
    ]

    # Use the list to generate permutations
    perm_list.each do |p|
      x = {
        :permutation_details => p,
        :depth => 1
      }

      # Generate the permutation
      if p[:type] == "prefix"
        x[:generated_permutation] = "#{p[:permutation]}#{baselist[0]}.#{brute_domain}"

      elsif p[:type] == "suffix"
        x[:generated_permutation] = "#{baselist[0]}#{p[:permutation]}.#{brute_domain}"

      elsif p[:type] == "both"
        # Prefix
        x[:generated_permutation] = "#{p[:permutation]}#{baselist[0]}.#{brute_domain}"

        # Suffix
        y = {
          :permutation_details => p,
          :generated_permutation => "#{baselist[0]}#{p[:permutation]}.#{brute_domain}",
          :depth => 1
        }
        work_q.push(y)
      end

      work_q.push(x)
    end

    # if we have a number, we should try to increment / decrement it
    if basename =~ /\d/
      # get the place of the first number
      place = basename =~ /\d/
      current_number = basename[place]

      # increment
      basename[place] = "#{current_number.to_i + 1}"
      #basename[place] = "#{current_number.to_i + 2}"
      #basename[place] = "#{current_number.to_i + 3}"
      #basename[place] = "#{current_number.to_i + 10}"
      #basename[place] = "#{current_number.to_i + 100}"
      #basename[place] = "#{current_number.to_i + 1000}"
      increment = {
        :permutation_details => p,
        :generated_permutation => "#{basename}",
        :depth => 1
      }
      work_q.push(increment)

      # decrement
      basename[place] = "#{current_number.to_i - 1}"
      #basename[place] = "#{current_number.to_i - 2}"
      #basename[place] = "#{current_number.to_i - 3}"
      #basename[place] = "#{current_number.to_i - 10}"
      #basename[place] = "#{current_number.to_i - 100}"
      #basename[place] = "#{current_number.to_i - 1000}"
      decrement = {
        :permutation_details => p,
        :generated_permutation => "#{basename}",
        :depth => 1
      }
      work_q.push(decrement)
    end

    # Create a pool of worker threads to work on the queue
    workers = (0...1).map do
      Thread.new do
        _log "Starting thread..."
        begin
          while work_item = work_q.pop(true)
            begin
              fqdn = "#{work_item[:generated_permutation]}"
              permutation = "#{work_item[:permutation]}"
              depth = work_item[:depth]

              # Try to resolve
              resolved_address = resolve_name(fqdn, Dnsruby::Types::A)

              if resolved_address # If we resolved, create the right entities

                unless wildcard_ips.include?(resolved_address)
                  _log_good "Resolved address #{resolved_address} for #{fqdn} and it wasn't in our wildcard list."
                  main_entity = _create_entity("DnsRecord", {"name" => fqdn })
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


  # Check for wildcard DNS
  def _check_wildcard(basename)
    _log "Checking for wildcards on #{basename}."

    all_discovered_wildcards = []

    # First we look for a single address that won't exist
    10.times do
      random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{basename}"
      resolved_address = resolve_name(random_string)

      # keep track of it unless we already have it
      unless resolved_address.nil? || all_discovered_wildcards.include?(resolved_address)
        all_discovered_wildcards << resolved_address
      end
    end

    # also - sometimes there appears to be a regex pattern that only matches our original

    # If that resolved, we know that we're in a wildcard situation.
    #
    # Some domains have a pool of IPs that they'll resolve to, so
    # let's go ahead and test a bunch of different domains to try
    # and collect those IPs
    if all_discovered_wildcards.uniq.count > 1
      _log "Multiple wildcard ips for #{basename} after resolving these: #{all_discovered_wildcards}."
      _log "Trying to create an exhaustive list."

      # Now we have to test for things that return a block of addresses as a wildcard.
      # we to be adaptive (to a point), so let's keep looking in chuncks until we find
      # no new ones...
      no_new_wildcards = false

      until no_new_wildcards
        _log "Testing #{all_discovered_wildcards.count * 20} new entries..."
        newly_discovered_wildcards = []

        (all_discovered_wildcards.count * 20).times do |x|
          random_string = "#{(0...8).map { (65 + rand(26)).chr }.join.downcase}.#{basename}"
          resolved_address = resolve(random_string)

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
