module Intrigue
  module Scanner
  class SimpleScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)

      if depth <= 0      # Check for bottom of recursion
        @scan_log.log "Returning, depth @ #{depth}"
        return
      end

      if _is_prohibited(entity)  # Check for prohibited entity name
        @scan_log.log "Returning, #{entity.inspect} prohibited"
        return
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
      elsif entity.type == "NetBlock"
        ### Masscan
        _start_task_and_recurse "masscan_scan",entity,depth
      elsif entity.type == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
      elsif entity.type == "Uri"
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.attributes["name"] =~ /^https/
        ### Gather links
        #_start_task_and_recurse "uri_gather_and_analyze_links",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth
        ### Dirbuster
        #_start_task_and_recurse "uri_dirbuster",entity,depth
        ### screenshot
        #_start_task_and_recurse "uri_screenshot",entity,depth
      elsif entity.type == "String" || entity.type == "Person"
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

      elsif entity.type == "IpAddress"
        # 23.x.x.x
        if entity.attributes["name"] =~ /^23./
          @scan_log.error "Skipping Akamai address"
          return true
        end

      else

        if (
          entity.attributes["name"] =~ /google/             ||
          entity.attributes["name"] =~ /g.co/               ||
          entity.attributes["name"] =~ /goo.gl/             ||
          entity.attributes["name"] =~ /android/            ||
          entity.attributes["name"] =~ /urchin/             ||
          entity.attributes["name"] =~ /schema.org/         ||
          entity.attributes["description"] =~ /schema.org/  ||
          entity.attributes["name"] =~ /microsoft.com/      ||
          entity.attributes["name"] =~ /facebook.com/       ||
          entity.attributes["name"] =~ /cloudfront.net/     ||
          entity.attributes["name"] =~ /twitter.com/        ||
          entity.attributes["name"] =~ /w3.org/             ||
          entity.attributes["name"] =~ /akamai/             ||
          entity.attributes["name"] =~ /akamaitechnologies/ ||
          entity.attributes["name"] =~ /amazonaws/          ||
          entity.attributes["name"] =~ /purl.org/           ||
          entity.attributes["name"] =~ /oclc.org/           ||
          entity.attributes["name"] =~ /youtube.com/        ||
          entity.attributes["name"] =~ /xmlns.com/          ||
          entity.attributes["name"] =~ /ogp.me/             ||
          entity.attributes["name"] =~ /rdfs.org/           ||
          entity.attributes["name"] =~ /drupal.org/         ||
          entity.attributes["name"] =~ /plus.google.com/    ||
          entity.attributes["name"] =~ /instagram.com/      ||
          entity.attributes["name"] =~ /zepheira.com/       ||
          entity.attributes["name"] == "feeds2.feedburner.com" )

            @scan_log.error "SKIP Prohibited entity: #{entity.type}##{entity.attributes["name"]}"
            return true

        end

      end
    false
    end

  end
end
end
