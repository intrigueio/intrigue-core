module Intrigue
module Strategy
class DnsSubdomain

    def self.handle_entity(project,task,entity,depth=2)
      return "not implemented"
    end

    def self.metadata
      {
        :name => "dns_subdomain",
        :pretty_name => "DNS Subdomain Scan",
        :authors => ["jcran"],
        :description => "Recursively scan for hostnames using an extensive wordlist, alphanumeric generation to 3 characters and permutations",
        :references => [],
        :allowed_types => ["DnsRecord"],
        :example_entities => [
          {"type" => "DnsRecord", "attributes" => {"name" => "intrigue.io"}}
        ],
        :allowed_options => [ ]
      }
    end

    private

    ###
    ### Main "workflow" function
    ###
    def _recurse(entity, depth)

      if depth <= 0      # Check for bottom of recursion
        @scan_result.logger.log "Returning, depth @ #{depth}"
        return
      end

      if entity.type_string == "DnsRecord"
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[
          {"name" => "use_file", "value" => true },
          {"name" => "threads", "value" => 5 },
          {"name" => "brute_alphanumeric_size", "value" => 3}
        ]
      else
        @scan_result.logger.log "Unhandled entity type: #{entity.type}##{entity.details["name"]}"
        return
      end
    end

end
end
end
