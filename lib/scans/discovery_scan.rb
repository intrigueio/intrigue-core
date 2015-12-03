module Intrigue
module Scanner
class DiscoveryScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)

      if depth <= 0      # Check for bottom of recursion
        @scan_result.logger.log "Returning, depth @ #{depth}"
        return
      end

      if entity.type_string == "DnsRecord"

        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth, ["name" => "record_types", "value" => "A,AAAA,MX,NS,SOA,TXT"]

        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[
          {"name" => "use_file", "value" => true },
          {"name" => "brute_alphanumeric_size", "value" => 3},
          {"name" => "use_permutations", "value" => true }
        ]

      elsif entity.type_string == "IpAddress"

        ### DNS Reverse Lookup
        _start_task_and_recurse "dns_lookup_reverse",entity,depth

        ### Whois
        _start_task_and_recurse "whois",entity,depth

        ### Scan
        _start_task_and_recurse "nmap_scan",entity,depth

      elsif entity.type_string == "NetBlock"

        ### Masscan
        if entity.details["whois_full_text"] =~ /#{@scan_result.base_entity.name}/
          _start_task_and_recurse "masscan_scan",entity,depth, ["port" => 443]
        end

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.name =~ /^https/

      else
        @scan_result.logger.log "SKIP Unhandled entity type: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

end
end
end
