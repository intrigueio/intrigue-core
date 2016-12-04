module Intrigue
module Strategy
  class Default < Intrigue::Strategy::Base

    def self.recurse(entity, task_result)
      puts "Recurse called for #{task_result.task_name} on #{entity}"
      puts "Task Result: #{task_result.inspect}"

      if task_result.depth == 0
        puts "Recurse called for #{task_result.task_name} on #{entity} but at max depth. Returning!"
        return nil
      end

      if is_prohibited entity
        puts "Skipped prohibited entity: #{entity}"
        return nil
      end

      if entity.type_string == "DnsRecord"
        start_recursive_task(task_result, "dns_lookup_forward", entity)

        ### DNS Subdomain Bruteforce
        # do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true },
            {"name" => "brute_alphanumeric_size", "value" => 3},
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false },
            {"name" => "threads", "value" => 5}])
        else
          # otherwise do something a little faster
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => false },
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false },
            {"name" => "threads", "value" => 2}])
        end

      elsif entity.type_string == "String"

        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 10}])

      elsif entity.type_string == "IpAddress"

        ### DNS Reverse Lookup
        start_recursive_task(task_result,"dns_lookup_reverse",entity)

        ### Scan
        start_recursive_task(task_result,"nmap_scan",entity)

        ### Whois
        start_recursive_task(task_result,"whois",entity)

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it
        cidr = entity.name.split("/").last.to_i
        if cidr >= 24
          start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 80}])
          start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 443}])
        end

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

        ## Spider, looking for metadata
        #start_recursive_task(task_result,"uri_spider",entity,[
        #    {"name" => "threads", "value" => 3},
        #    {"name" => "max_pages", "value" => 250},
        #    {"name" => "extract_dns_records", "value" => true},
        #    {"name" => "extract_patterns", "value" => "defense.gov"}]) unless entity.created_by? "uri_brute"

        # Check for exploitable URIs, but don't recurse on things we've already found
        start_recursive_task(task_result,"uri_brute", entity, [{"name"=> "threads", "value" => 3}, {"name" => "user_list", "value" => "admin,test,server-status,robots.txt"}]) unless entity.created_by? "uri_brute"

      else
        puts "No actions for entity: #{entity.type}##{entity.attributes["name"]}"
        return
      end
    end

    def self.is_prohibited entity

      if entity.type_string == "IpAddress"
        # 23.x.x.x
        if entity.name =~ /^23\./             ||  # akamai
           entity.name =~ /^2600:1400/        ||  # akamai
           entity.name =~ /^2600:1409/        ||  # akamai
           entity.name =~ /^127\.\0\.0\.*$/   ||  # RFC1918
           entity.name =~ /^10\.*$/           ||  # RFC1918
           entity.name =~ /^0.0.0.0/
          return true
        end
      end

      # Standard exclusions
      if (
        entity.name =~ /^.*1e100.com$/                     ||
        entity.name =~ /^.*1e100.net$/                     ||
        entity.name =~ /^.*akam.net$/                      ||
        entity.name =~ /^.*akamai$/                        ||
        entity.name =~ /^.*akamaitechnologies$/            ||
        entity.name =~ /^.*amazonaws.com$/                 ||
        entity.name =~ /^.*android$/                       ||
        entity.name =~ /^.*android.clients.google.com$/    ||
        entity.name =~ /^.*android.com$/                   ||
        entity.name =~ /^.*cloudfront.net$/                ||
        entity.name =~ /^.*drupal.org$/                    ||
        entity.name =~ /^.*facebook.com$/                  ||
        entity.name =~ /^.*feeds2.feedburner.com$/         ||
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
        entity.name =~ /^.*localhost$/                     ||
        entity.name =~ /^.*mandrillapp.com$/               ||
        entity.name =~ /^.*marketo.com$/                   ||
        entity.name =~ /^.*metric.gstatic.com$/            ||
        entity.name =~ /^.*microsoft.com$/                 ||
        entity.name =~ /^.*oclc.org$/                      ||
        entity.name =~ /^.*ogp.me$/                        ||
        entity.name =~ /^.*plus.google.com$/               ||
        entity.name =~ /^.*root-servers.net$/              ||
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
        entity.name =~ /^.*zepheira.com$/                  ||
        entity.name =~ /^.akamaiedge.net$/                 ||
        entity.name =~ /^.amazonaws.com$/                  ||
        entity.name =~ /^.azure-mobile.net$/               ||
        entity.name =~ /^.azureedge-test.net$/             ||
        entity.name =~ /^.azureedge.net$/                  ||
        entity.name =~ /^.azurewebsites.net$/              ||
        entity.name =~ /^.cloudapp.net$/                   ||
        entity.name =~ /^.edgecastcdn.net$/                ||
        entity.name =~ /^.edgekey.net$/                    ||
        entity.name =~ /^.herokussl.com$/                  ||
        entity.name =~ /^.msn.com$/                        ||
        entity.name =~ /^.outook.com$/                     ||
        entity.name =~ /^.secureserver.net$/               ||
        entity.name =~ /^.v0cdn.net$/                      ||
        entity.name =~ /^.windowsphone-int.net$/           ||
        entity.name =~ /^.windows.net$/                    ||
        entity.name =~ /^.windowsphone.com$/
       )

        puts "SKIP Prohibited entity: #{entity.type}##{entity.name}"
        return true
      end

    end


end
end
end
