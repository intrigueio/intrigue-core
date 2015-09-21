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
        _start_task_and_recurse "nmap_scan",entity,depth
        ### Geolocate
        #_start_task "geolocate_host",entity,depth
      elsif entity.type == "NetBlock"
        ### Masscan
        _start_task_and_recurse "masscan_scan",entity,depth
      elsif entity.type == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth

        ### DNS Subdomain Bruteforce
        #
        # If it's a TLD or primary domain, do a full brute
        #
        if entity.attributes["name"].split(".").count <= 2
          _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "true"}]
        #
        # otherwise, just quick brute
        #
        else
          _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
        end
      elsif entity.type == "Uri"
        ### screenshot
        #_start_task_and_recurse "uri_http_screenshot",entity,depth
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.attributes["name"] =~ /^https/
        ### Gather links
        #_start_task_and_recurse "uri_gather_and_analyze_links",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth,[{"name" => "max_pages", "value" => 100}]
        ### Dirbuster
        #_start_task_and_recurse "uri_dirbuster",entity,depth
      elsif entity.type == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 30}]
        # Brute TLD
        #_start_task_and_recurse "dns_brute_tld",entity,depth
      #elsif entity.type = entity.type == "Person" || entity.type == "EmailAddress"
        # Search Pipl
        #_start_task_and_recurse "search_pipl",entity,depth
      elsif entity.type == "Organization"
        # Check EDGAR
        _start_task_and_recurse "search_edgar",entity,depth
      else
        @scan_log.log "SKIP Unhandled entity type: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

    # List of prohibited entities - returns true or false
    def _is_prohibited entity

      ## First, check the filter list
      @filter_list.each do |filter|
        if entity.attributes["name"] =~ /#{filter}/
          @scan_log.log "Filtering #{entity.attributes["name"]} based on filter #{filter}"
          return true
        end
      end


      if entity.type == "NetBlock"

        cidr = entity.attributes["name"].split("/").last.to_i
        unless cidr >= 22
          @scan_log.error "SKIP Netblock too large: #{entity.type}##{entity.attributes["name"]}"
          return true
        end

        # skip ipv6 for now (#30)
        if entity.attributes["name"] =~ /::/
          @scan_log.error "SKIP IPv6 is currently unhandled"
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
          entity.attributes["name"] =~ /google.com/         ||
          entity.attributes["name"] =~ /goo.gl/             ||
          entity.attributes["name"] =~ /android/            ||
          entity.attributes["name"] =~ /urchin/             ||
          entity.attributes["name"] =~ /schema.org/         ||
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
          entity.attributes["name"] =~ /gandi.net/          ||
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
