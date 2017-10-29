module Intrigue
module Strategy
  class AssetDiscoveryPassive < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "asset_discovery_passive",
        :pretty_name => "Asset Discovery (Passive)",
        :passive => true,
        :authors => ["jcran"],
        :description => "This strategy tries to enumerate assets without touching the attack surface."
      }
    end

    def self.recurse(entity, task_result)

      if entity.type_string == "DnsRecord"

        ### AWS_S3_brute the domain name and the base name
        base_name = entity.name.split(".")[0...-1].join(".")
        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => "#{base_name}"}
        ])

        # Do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)

          # Sublister API
          start_recursive_task(task_result,"search_sublister", entity)

          # CRT Scraper
          start_recursive_task(task_result,"search_crt", entity )

          # Threatcrowd API... skip resolutions, as we probably don't want old
          # data for this use case
          start_recursive_task(task_result,"search_threatcrowd", entity, [
            {"name" => "gather_resolutions", "value" => true },
            {"name" => "gather_subdomains", "value" => true }])

          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true },
            {"name" => "threads", "value" => 1 }])
        else
          # otherwise do something a little faster
          start_recursive_task(task_result,"dns_brute_sub",entity,[])
        end

      elsif entity.type_string == "EmailAddress"
        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      #elsif entity.type_string == "FtpServer"
      #  start_recursive_task(task_result,"ftp_banner_grab",entity)

      elsif entity.type_string == "IpAddress"

        # Prevent us from hammering on whois services
        unless ( entity.created_by?("net_block_expand"))
          start_recursive_task(task_result,"whois",entity)
        end

        # Rather than scanning, let's use a service to look it up
        start_recursive_task(task_result,"search_censys",entity)

        # Rather than scanning, let's use a service to look it up
        #start_recursive_task(task_result,"search_shodan",entity)

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, expand it
        if entity.details["whois_full_text"] =~ /#{task_result.scan_result.base_entity.name}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"net_block_expand",entity)
        else
          task_result.log "Cowardly refusing to expand this netblock.. it doesn't look like ours."
        end

      elsif entity.type_string == "Person"
        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      elsif entity.type_string == "String"
        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      elsif entity.type_string == "Uri"

        #unless (entity.created_by?("uri_brute") || entity.created_by?("uri_spider") )

          ## Grab the SSL Certificate
          start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

          ## Super-lite spider, looking for metadata
          #start_recursive_task(task_result,"uri_spider",entity,[
          #    {"name" => "max_pages", "value" => 5 },
          #    {"name" => "extract_dns_records", "value" => true },
          #    {"name" => "extract_dns_record_pattern", "value" => "#{task_result.scan_result.base_entity.name}"}])

        #end
      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
