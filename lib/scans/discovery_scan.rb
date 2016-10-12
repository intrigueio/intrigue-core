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
      :allowed_types => ["DnsRecord", "IpAddress", "NetBlock","String"],
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
        # do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)
          _start_task_and_recurse "dns_brute_sub",entity,depth,[
            {"name" => "use_file", "value" => true },
            {"name" => "brute_alphanumeric_size", "value" => 1},
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false }
          ]
        else
          # otherwise do something a little faster
          _start_task_and_recurse "dns_brute_sub",entity,depth,[
            {"name" => "use_file", "value" => false },
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false }
          ]
        end

        ### DNS Forward Lookup
        _start_task_and_recurse "dns_lookup_forward",entity,depth, ["name" => "record_types", "value" => "A,AAAA"]

      elsif entity.type_string == "String"

        # Search, only snag the top result
        _start_task_and_recurse "search_bing",entity,depth,[{"name"=> "max_results", "value" => 1}]

      elsif entity.type_string == "IpAddress"

        ### DNS Reverse Lookup
        _start_task_and_recurse "dns_lookup_reverse",entity,depth

        ### Scan
        _start_task_and_recurse "nmap_scan",entity,depth

        ### Whois
        _start_task_and_recurse "whois",entity,depth

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it
        cidr = entity.name.split("/").last.to_i
        if cidr >=18
          _start_task_and_recurse "masscan_scan",entity,depth, ["port" => 80]
          _start_task_and_recurse "masscan_scan",entity,depth, ["port" => 443]
        else
          _start_task_and_recurse "masscan_scan",entity,depth
        end

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        _start_task_and_recurse "uri_gather_ssl_certificate",entity,depth if entity.name =~ /^https/

        # Check for exploitable URIs, but don't recurse on things we've already found
        #_start_task_and_recurse "uri_exploitable", entity, depth,[{"name"=> "threads", "value" => 5}] unless entity.created_by? "uri_exploitable"

        ## Spider, looking for metadata
        _start_task_and_recurse "uri_spider",entity,depth,[
            {"name" => "threads", "value" => 5},
            {"name" => "max_pages", "value" => 250},
            {"name" => "extract_dns_records", "value" => true},
            {"name" => "extract_patterns", "value" => @scan_result.base_entity["name"]}
        ] unless entity.created_by? "uri_exploitable"

      else
        @scan_result.logger.log "No actions for entity: #{entity.type}##{entity.attributes["name"]}"
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
        entity.name =~ /^.*feeds2.feedburner.com$/         ||
        entity.name =~ /^.*1e100.com$/                     ||
        entity.name =~ /^.*1e100.net$/                     ||
        entity.name =~ /^.*akamai$/                        ||
        entity.name =~ /^.*akamaitechnologies$/            ||
        entity.name =~ /^.*amazonaws.com$/                 ||
        entity.name =~ /^.*android$/                       ||
        entity.name =~ /^.*android.clients.google.com$/    ||
        entity.name =~ /^.*android.com$/                   ||
        entity.name =~ /^.*cloudfront.net$/                ||
        entity.name =~ /^.*drupal.org$/                    ||
        entity.name =~ /^.*facebook.com$/                  ||
        entity.name =~ /^.*g.co$/                          ||
        entity.name =~ /^.*gandi.net$/                     ||
        entity.name =~ /^.*goo.gl$/                        ||
        entity.name =~ /^.*google-analytics.com$/          ||
        entity.name =~ /^.*google.ca$/                     ||
        entity.name =~ /^.*google.cl$/                     ||
        entity.name =~ /^.*google.co.in$/                  ||
        entity.name =~ /^.*google.co.jp$/                  ||
        entity.name =~ /^.*google.co.uk$/                  ||
        entity.name =~ /^.*google.com$/                    ||
        entity.name =~ /^.*google.com.ar$/                 ||
        entity.name =~ /^.*google.com.au$/                 ||
        entity.name =~ /^.*google.com.br$/                 ||
        entity.name =~ /^.*google.com.co$/                 ||
        entity.name =~ /^.*google.com.mx$/                 ||
        entity.name =~ /^.*google.com.tr$/                 ||
        entity.name =~ /^.*google.com.vn$/                 ||
        entity.name =~ /^.*google.de$/                     ||
        entity.name =~ /^.*google.es$/                     ||
        entity.name =~ /^.*google.fr$/                     ||
        entity.name =~ /^.*google.hu$/                     ||
        entity.name =~ /^.*google.it$/                     ||
        entity.name =~ /^.*google.nl$/                     ||
        entity.name =~ /^.*google.pl$/                     ||
        entity.name =~ /^.*google.pt$/                     ||
        entity.name =~ /^.*googleadapis.com$/              ||
        entity.name =~ /^.*googleapis.cn$/                 ||
        entity.name =~ /^.*googlecommerce.com$/            ||
        entity.name =~ /^.*googlevideo.com$/               ||
        entity.name =~ /^.*gstatic.cn$/                    ||
        entity.name =~ /^.*gstatic.com$/                   ||
        entity.name =~ /^.*gvt1.com$/                      ||
        entity.name =~ /^.*gvt2.com$/                      ||
        entity.name =~ /^.*hubspot.com$/                   ||
        entity.name =~ /^.*instagram.com$/                 ||
        entity.name =~ /^.*metric.gstatic.com$/            ||
        entity.name =~ /^.*mandrillapp.com$/               ||
        entity.name =~ /^.*marketo.com$/                   ||
        entity.name =~ /^.*microsoft.com$/                 ||
        entity.name =~ /^.*oclc.org$/                      ||
        entity.name =~ /^.*ogp.me$/                        ||
        entity.name =~ /^.*plus.google.comv/               ||
        entity.name =~ /^.*purl.org$/                      ||
        entity.name =~ /^.*rdfs.org$/                      ||
        entity.name =~ /^.*schema.org$/                    ||
        entity.name =~ /^.*twitter.com$/                   ||
        entity.name =~ /^.*urchin$/                        ||
        entity.name =~ /^.*urchin.com$/                    ||
        entity.name =~ /^.*url.google.com$/                ||
        entity.name =~ /^.*w3.org$/                        ||
        entity.name =~ /^.*www.goo.gl$/                    ||
        entity.name =~ /^.*xmlns.com$/                     ||
        entity.name =~ /^.*youtu.be$/                      ||
        entity.name =~ /^.*youtube-nocookie.com$/          ||
        entity.name =~ /^.*youtube.com$/                   ||
        entity.name =~ /^.*youtubeeducation.com$/          ||
        entity.name =~ /^.*ytimg.com$/                     ||
        entity.name =~ /^.*zepheira.com$/
       )

        @scan_result.logger.log_error "SKIP Prohibited entity: #{entity.type}##{entity.name}"
        return true
      end

    end

end
end
end
