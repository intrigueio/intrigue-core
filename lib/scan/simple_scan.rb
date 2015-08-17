module Intrigue
  module Scanner
  class SimpleScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)
      # Check for bottom of recursion
      return if depth <= 0

      # Check for prohibited entity name
      if entity.attributes
        return if _is_prohibited entity
      end

      if entity.type == "IpAddress"
        ### DNS Reverse Lookup
        _start_task_and_recurse "dns_lookup_reverse",entity,depth
        ### Whois
        _start_task_and_recurse "whois",entity,depth
        ### Shodan
        #_start_task_and_recurse "search_shodan",entity,depth
        ### Scan
        #_start_task_and_recurse "nmap_scan",entity,depth
        ### Geolocate
        #_start_task "geolocate_host",entity,depth
      elsif  entity.type == "NetBlock"
        ### Masscan
        _start_task_and_recurse "masscan_scan",entity,depth
      elsif entity.type == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
      elsif entity.type == "Uri"
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth
        ### Gather links
        _start_task_and_recurse "uri_gather_and_analyze_links",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth
        ### Dirbuster
        _start_task_and_recurse "uri_dirbuster",entity,depth
        ### screenshot
        #_start_task_and_recurse "uri_screenshot",entity,depth
      elsif entity.type == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 20}]
        # Brute TLD
        #_start_task_and_recurse "dns_brute_tld",entity,depth
      else
        @scan_log.log "SKIP Unhandled entity type: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

    # List of prohibited entities - returns true or false
    def _is_prohibited entity

      if entity.type == "NetBlock"
        cidr = entity.attributes["name"].split("/").last.to_i
        unless cidr >= 20
          @scan_log.error "SKIP Netblock too large: #{entity.type}##{entity.attributes["name"]}"
          return true
        end
      else
        if (
          entity.attributes["name"] =~ /google/             ||
          entity.attributes["name"] =~ /g.co/               ||
          entity.attributes["name"] =~ /goo.gl/             ||
          entity.attributes["name"] =~ /android/            ||
          entity.attributes["name"] =~ /urchin/             ||
          entity.attributes["name"] =~ /youtube/            ||
          entity.attributes["name"] =~ /schema.org/         ||
          entity.attributes["description"] =~ /schema.org/  ||
          entity.attributes["name"] =~ /microsoft.com/      ||
          #entity.attributes["name"] =~ /yahoo.com/         ||
          entity.attributes["name"] =~ /facebook.com/       ||
          entity.attributes["name"] =~ /cloudfront.net/     ||
          entity.attributes["name"] =~ /twitter.com/        ||
          entity.attributes["name"] =~ /w3.org/             ||
          entity.attributes["name"] =~ /akamai/             ||
          entity.attributes["name"] =~ /akamaitechnologies/ ||
          entity.attributes["name"] =~ /amazonaws/          ||
          entity.attributes["name"] == "feeds2.feedburner.com"
        )

          @scan_log.error "SKIP Prohibited entity: #{entity.type}##{entity.attributes["name"]}"
          return true

        end

      end
    false
    end

  end
end
end
