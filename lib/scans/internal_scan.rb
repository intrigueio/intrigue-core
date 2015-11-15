module Intrigue
  module Scanner
  class InternalScan < Intrigue::Scanner::Base

    private

    ### Main "workflow" function
    #
    def _recurse(entity, depth)

      if depth <= 0 # Check for bottom of recursion
        @scan_result.logger.log "Returning, depth @ #{depth}"
        return
      end

      if _is_prohibited(entity)   # Check for prohibited entity name
        @scan_result.logger.log "Returning, #{entity.inspect} prohibited"
        return
      end

      if entity.type_string == "IpAddress"
        ### DNS Reverse Lookup
        _start_task_and_recurse "dns_lookup_reverse",entity,depth
        ### Scan
        _start_task_and_recurse "nmap_scan",entity,depth
        ### Geolocate
        #_start_task "geolocate_host",entity,depth
      elsif  entity.type_string == "NetBlock"
        ### nmap
        _start_task_and_recurse "nmap_scan",entity,depth
      elsif entity.type_string == "DnsRecord"
        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth
        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "true"}]
      elsif entity.type_string == "Uri"
        ### Get SSLCert
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth
        ### spider
        _start_task_and_recurse "uri_spider",entity,depth,[{"name" => "max_pages", "value" => 100}]
        ### Dirbuster
        _start_task_and_recurse "uri_dirbuster",entity,depth
        ### screenshot
        _start_task_and_recurse "uri_http_screenshot",entity,depth
        ### Gather links
        _start_task_and_recurse "uri_gather_and_analyze_links",entity,depth
      elsif entity.type_string == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 10}]
        # Brute TLD
        #_start_task_and_recurse "dns_brute_tld",entity,depth
      else
        @scan_result.logger.log "SKIP Unhandled entity type: #{entity.type} #{entity.name}"
        return
      end

      @scan_result.timestamp_end = DateTime.now
    end

    def _is_prohibited entity

      @filter_list.each do |filter|
        if entity.name.to_s =~ /#{filter}/
          @scan_result.logger.log "SKIP Filtering #{entity.name} based on filter #{filter}"
          return true
        end
      end

      # Skip huge netblocks, ipv6
      if entity.type_string == "NetBlock"

        # handle netblock
        cidr = entity.name.split("/").last.to_i
        unless cidr >= 16
          @scan_result.logger.log_error "SKIP Netblock too large: #{entity.type}##{entity.name}"
          return true
        end

        # skip ipv6 for now (#30)
        if entity.name =~ /::/
          @scan_result.logger.log_error "SKIP IPv6 is currently unhandled"
          return true
        end
      end

      # Standard exclusions
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

        @scan_result.logger.log_error "SKIP Prohibited entity: #{entity.type}##{entity.name}"
        return true
      end

      # otherwise
      false
    end


  end
end
end
