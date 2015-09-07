module Intrigue
  module Scanner
  class InternalScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)
      # Check for bottom of recursion
      return if depth <= 0

      # Check for prohibited entity name
      return if _is_prohibited entity

      if entity.type == "IpAddress"
        ### DNS Reverse Lookup
        _start_task_and_recurse "dns_lookup_reverse",entity,depth
        ### Scan
        _start_task_and_recurse "nmap_scan",entity,depth
        ### Geolocate
        #_start_task "geolocate_host",entity,depth
      elsif  entity.type == "NetBlock"
        ### nmap
        _start_task_and_recurse "nmap_scan",entity,depth
      elsif entity.type == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => true }]
      elsif entity.type == "Uri"
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth
        ### Dirbuster
        _start_task_and_recurse "uri_dirbuster",entity,depth
        ### screenshot
        _start_task_and_recurse "uri_screenshot",entity,depth
        ### Gather links
        _start_task_and_recurse "uri_gather_and_analyze_links",entity,depth
      elsif entity.type == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 10}]
        # Brute TLD
        #_start_task_and_recurse "dns_brute_tld",entity,depth
      else
        @scan_log.log "Unhandled entity type: #{entity.type} #{entity.attributes["name"]}"
        return
      end
    end

    def _is_prohibited entity
      false # nothing is safe!
    end


  end
end
end
