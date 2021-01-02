module Intrigue
module Task
class DnsPermute < BaseTask

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "dns_permute",
      :pretty_name => "DNS Permute",
      :authors => ["jcran"],
      :description => "Given a Domain or DnsRecord, find others that are like it",
      :references => [],
      :type => "discovery",
      :passive => false,
      :allowed_types => ["Domain","DnsRecord"],
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
    if parse_domain_name(basename) == basename
      brute_domain = basename
    else 
      brute_domain = baselist[1..-1].join(".")
    end

    # Check for wildcard DNS, modify behavior appropriately. (Only create entities
    # when we know there's a new host associated)

    wildcard_ips = check_wildcard(brute_domain)

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
              resolved_address = resolve_name(fqdn)

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
  
end
end
end
