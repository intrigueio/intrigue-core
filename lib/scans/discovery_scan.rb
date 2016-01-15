module Intrigue
module Scanner
class DiscoveryScan < Intrigue::Scanner::Base

  def metadata
    {
      :name => "discovery",
      :pretty_name => "Discovery Scan",
      :authors => ["jcran"],
      :description => "Discovery Scan",
      :references => [],
      :allowed_types => ["DnsRecord", "IpAddress", "NetBlock", "String", "Uri"],
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

      if _is_prohibited entity
        @scan_result.logger.log "Skipped prohibited entity: #{entity}"
        return
      end

      if entity.type_string == "DnsRecord"

        ### DNS Subdomain Bruteforce
        _start_task_and_recurse "dns_brute_sub",entity,depth,[
          {"name" => "use_file", "value" => true },
          {"name" => "brute_alphanumeric_size", "value" => 1},
          {"name" => "use_permutations", "value" => true }
        ]

        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth, ["name" => "record_types", "value" => "A,AAAA"]


      elsif entity.type_string == "String"
        # Search!
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 3}]

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
          _start_task_and_recurse "masscan_scan",entity,depth, ["port" => 443] if entity
        end

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.name =~ /^https/

        # uri_exploitable
        _start_task_and_recurse "uri_exploitable",entity,depth

      else
        @scan_result.logger.log "SKIP Unhandled entity type: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

    def _is_prohibited entity

      ## First, check the filter list
      @filter_list.each do |filter|
        if entity.name =~ /#{filter}/
          @scan_result.logger.log "Filtering #{entity.name} based on filter #{filter}"
          return true
        end
      end

      if entity.type_string == "NetBlock"
        cidr = entity.name.split("/").last.to_i

        if cidr <= 16
          @scan_result.logger.log_error "SKIP Netblock too large: #{entity.type}##{entity.name}"
          return true
        elsif entity.name =~ /:/ # it's an ipv6 address, skip it
          @scan_result.logger.log_error "SKIP IPv6 block: #{entity.type}##{entity.name}"
          return true
        end

      elsif entity.type_string == "IpAddress"
        # 23.x.x.x
        if entity.name =~ /^23./
          @scan_result.logger.log_error "Skipping Akamai address"
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
        entity.name =~ /amazonaws.com/      ||
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

    end

end
end
end
