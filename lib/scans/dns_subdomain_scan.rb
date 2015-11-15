module Intrigue
module Scanner
class DnsSubdomainScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)

      if depth <= 0      # Check for bottom of recursion
        @scan_result.log "Returning, depth @ #{depth}"
        return
      end

      if entity.type_string == "DnsRecord"
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "true"}]
      else
        @scan_result.log "SKIP Unhandled entity type: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

end
end
end
