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
      :allowed_options => [
        {:name => "threads", :regex => "integer", :default => 3 }
      ],
      :created_types => ["DnsRecord"]
    }
  end

  def run
    super

    # Set the basename
    basename = _get_entity_name
    thread_count = _get_option "threads"

    # gracefully decline to permute these..
    skip_regexes = [ /^.*s3.*\.amazonaws.com$/,  ]
    skip_regexes.each do |r|
      if basename =~ /r/
        _log_error "Unable to permute, too many false positives to make it worthwhile"
        return
      end
    end

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
    wildcard_responses = gather_wildcard_resolutions(brute_domain, true)
    _log "Using wildcard ips as: #{wildcard_responses}"


    # Create a queue to hold our list of attempts
    work_q = Queue.new

    # grab the common permutation list (data helper)
    perm_list = common_dns_permuation_list

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
        :generated_permutation => "#{basename}.#{brute_domain}",
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
        :generated_permutation => "#{basename}.#{brute_domain}",
        :depth => 1
      }
      work_q.push(decrement)
    end

    # Create a pool of worker threads to work on the queue
    workers = (0...thread_count).map do
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
                _log "Resolved: #{fqdn} to #{resolved_address}"

                unless wildcard_responses.include?(resolved_address)
                  _log_good "Resolved address #{resolved_address} for #{fqdn} and it wasn't in our wildcard list."
                  main_entity = _create_entity("DnsRecord", {"name" => fqdn })
                end

              else
                _log "Did not resolve: #{fqdn}"
              end
            end
          end # end while
        rescue ThreadError => e
          _log_error "Caugh thread error: #{e}"
        end
      end
    end; "ok"
    workers.map(&:join); "ok"
  end

end
end
end
