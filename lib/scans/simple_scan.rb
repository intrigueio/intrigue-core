module Intrigue
  module Scanner
  class SimpleScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)

      if depth <= 0      # Check for bottom of recursion
        @scan_result.log "Returning, depth @ #{depth}"
        return
      end

      if _is_prohibited(entity)  # Check for prohibited entity name
        @scan_result.log "Returning, #{entity.inspect} prohibited"
        return
      end

      if entity.type_string == "IpAddress"
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
      elsif entity.type_string == "NetBlock"
        ### Masscan
        _start_task_and_recurse "masscan_scan",entity,depth
      elsif entity.type_string == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth

        ### DNS Subdomain Bruteforce
        #
        # If it's a TLD or primary domain, do a full brute
        #
        if entity.name.split(".").count <= 2
          _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "true"}]
        #
        # otherwise, just quick brute
        #
        else
          _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
        end
      elsif entity.type_string == "Uri"
        ### screenshot
        #_start_task_and_recurse "uri_http_screenshot",entity,depth
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.name =~ /^https/
        ### Gather links
        _start_task_and_recurse "uri_gather_technology",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth,[{"name" => "max_pages", "value" => 100}]
        ### Dirbuster
        _start_task_and_recurse "uri_dirbuster",entity,depth
      elsif entity.type_string == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 30}]
        # Brute TLD
        #_start_task_and_recurse "dns_brute_tld",entity,depth
      elsif entity.type_string = entity.type_string == "Person" || entity.type_string == "EmailAddress"
        # Search Pipl
        @scan_result.log "SKIP Unhandled entity type: #{entity.type}##{entity.name}"
        #_start_task_and_recurse "search_pipl",entity,depth
        #_start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 1}]
      elsif entity.type_string == "Organization"
        # Check EDGAR
        _start_task_and_recurse "search_edgar",entity,depth
      else
        @scan_result.log "SKIP Unhandled entity type: #{entity.type}##{entity.name}"
        return
      end
    end

    # List of prohibited entities - returns true or false
    def _is_prohibited entity

      ## First, check the filter list
      @filter_list.each do |filter|
        if entity.name =~ /#{filter}/
          @scan_result.log "Filtering #{entity.name} based on filter #{filter}"
          return true
        end
      end

      if entity.type_string == "NetBlock"
        cidr = entity.name.split("/").last.to_i
        unless cidr >= 22
          @scan_result.log_error "SKIP Netblock too large: #{entity.type}##{entity.name}"
          return true
        end

      elsif entity.type_string == "IpAddress"
        # 23.x.x.x
        if entity.name =~ /^23./
          @scan_result.log_error "Skipping Akamai address"
          return true
        end

      else
        if (
          entity.name =~ /google.com/         ||
          entity.name =~ /goo.gl/             ||
          entity.name =~ /android/            ||
          entity.name =~ /urchin/             ||
          entity.name =~ /schema.org/         ||
          entity.name =~ /microsoft.com/      ||
          entity.name =~ /facebook.com/       ||
          entity.name =~ /cloudfront.net/     ||
          entity.name =~ /twitter.com/        ||
          entity.name =~ /w3.org/             ||
          entity.name =~ /akamai/             ||
          entity.name =~ /akamaitechnologies/ ||
          entity.name =~ /amazonaws/          ||
          entity.name =~ /purl.org/           ||
          entity.name =~ /oclc.org/           ||
          entity.name =~ /youtube.com/        ||
          entity.name =~ /xmlns.com/          ||
          entity.name =~ /ogp.me/             ||
          entity.name =~ /rdfs.org/           ||
          entity.name =~ /drupal.org/         ||
          entity.name =~ /plus.google.com/    ||
          entity.name =~ /instagram.com/      ||
          entity.name =~ /zepheira.com/       ||
          entity.name =~ /gandi.net/          ||
          entity.name == "feeds2.feedburner.com" )

            @scan_result.log_error "SKIP Prohibited entity: #{entity.type}##{entity.name}"
            return true
        end

      end
    false
    end

  end
end
end
