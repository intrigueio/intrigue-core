module Intrigue
  module Scanner
  class InternalScan < Intrigue::Scanner::Base

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
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "true"}]
      elsif entity.type == "Uri"
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth
        ### Dirbuster
        _start_task_and_recurse "uri_dirbuster",entity,depth
        ### screenshot
        _start_task_and_recurse "uri_http_screenshot",entity,depth
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

      @filter_list.each do |filter|
        if entity.attributes["name"].to_s =~ /#{filter}/
          @scan_log.log "SKIP Filtering #{entity.attributes["name"]} based on filter #{filter}"
          return true
        end
      end

      # Standard exclusions
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

      # otherwise
      false
    end


  end
end
end
