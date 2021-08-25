module Intrigue
  module Task
  class DnsBruteSharedTenantNames < BaseTask

    include Intrigue::Task::Dns

    def self.metadata
      {
        :name => "dns_brute_shared_tenant_names",
        :pretty_name => "DNS Brute Shared Tenant Names",
        :authors => ["jcran"],
        :description => "Given a Domain or DnsRecord, brute out dns names based on a service that allows the user to control the tenant name",
        :references => [],
        :type => "discovery",
        :passive => false,
        :allowed_types => [ "Domain", "DnsRecord", "UniqueKeyword"],
        :example_entities =>  [
          {"type" => "Domain", "details" => {"name" => "intrigue.io"}}
        ],
        :allowed_options => [
          { :name => "service_name", :regex => "alpha_numeric", :default => "*" },
          {:name => "threads", :regex => "integer", :default => 1 }
        ],
        :created_types => ["DnsRecord"]
      }
    end

    def run
      super

      known_services = [
        {
          name: 'acquia-sites-prod',
          domain: 'prod.acquia-sites.com',
          verify_method: :dns
        },{
          name: 'acquia-sites-dev',
          domain: 'dev.acquia-sites.com',
          verify_method: :dns
        },{
          name: 'acquia-sites-enterprise-g1',
          domain: 'enterprise-g1.acquia-sites.com',
          verify_method: :dns
        },{
          name: 'acquia-sites-devcloud',
          domain: 'devcloud.acquia-sites.com',
          verify_method: :dns
        },
        {
          name: 'microsoft-powerapps',
          domain: 'powerappsportals.com',
          verify_method: :dns
        }
        #,{
        #  name: 'hubspot',
        #  domain: 'hs-sites.com',
        #  verify_method: :content_body,
        #  positive_body_regexes: //,
        #  negative_body_regexes: [
        #    /Our website provider is having trouble loading this page/,
        #    /This page isn’t available/
        #  ]
        #}
      ]

      # Set the basename
      basename = _get_entity_name
      service_requested = _get_option 'service_name'
      thread_count = _get_option "threads"

      if service_requested == "*"
        services = known_services
      else # only one service
        services = known_services.select{ |x| x[:name] == service_requested }
      end

      services.each do |service|

        # error checking
        unless service
          _log_error "unable to find chosen service: #{service_requested}"
        else
          method = service[:verify_method]
          brute_domain = service[:domain]
        end

        # figure out all of our permutation points here.
        # "google.com" < 1 permutation point?
        # "1.yahoo.com"  < 2 permutation points?
        # "1.test.2.yahoo.com" < 3 permutation points?
        # "1.2.3.4.yahoo.com" < 5 permutation points?
        keywords = basename.split(".")

        # Check for wildcard DNS, modify behavior appropriately. (Only create entities
        # when we know there's a new host associated)
        wildcard_responses = gather_wildcard_resolutions(brute_domain, true)
        _log "Using wildcard ips as: #{wildcard_responses}"

        # Create a queue to hold our list of attempts
        work_q = Queue.new

        # get the shared list of permutations (data helper)
        perm_list = common_dns_permuation_list

        # Use the list to generate permutations
        perm_list.each do |p|
          x = {
            :permutation_details => p,
          }

          # Generate the permutation
          if p[:type] == "prefix"
            x[:generated_permutation] = "#{p[:permutation]}#{keywords[0]}.#{brute_domain}"

          elsif p[:type] == "suffix"
            x[:generated_permutation] = "#{keywords[0]}#{p[:permutation]}.#{brute_domain}"

          elsif p[:type] == "both"
            # Prefix
            x[:generated_permutation] = "#{p[:permutation]}#{keywords[0]}.#{brute_domain}"

            # Suffix
            y = {
              :permutation_details => p,
              :generated_permutation => "#{keywords[0]}#{p[:permutation]}.#{brute_domain}",
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
        workers = (0...thread_count).map do
          Thread.new do
            _log "Starting thread for #{service[:name]}"
            begin
              while work_item = work_q.pop(true)
                begin

                  fqdn = "#{work_item[:generated_permutation]}"
                  permutation = "#{work_item[:permutation]}"
                  depth = work_item[:depth]

                  if method == :dns # Try to resolve

                    resolved_address = resolve_name(fqdn)

                    if resolved_address # If we resolved, create the right entities
                      _log "Resolved: #{fqdn} to #{resolved_address}"

                      unless wildcard_responses.include?(resolved_address)
                        _log_good "Resolved address #{resolved_address} for #{fqdn} and it wasn't in our wildcard list."
                        main_entity = _create_entity("DnsRecord", {"name" => fqdn })
                      end
                    else
                      _log "Did not resolve #{fqdn}"
                    end

                  end
                end
              end # end while
            rescue ThreadError => e
              _log_error "Caught thread error: #{e}"
            end
          end
        end; "ok"
        workers.map(&:join); "ok"

      end # end services

    end

  end
  end
  end
