module Intrigue
module Strategy
  class OrgAssetDiscoveryPassive < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "org_asset_discovery_passive",
        :pretty_name => "Org Asset Discovery (Passive)",
        :passive => true,
        :user_selectable => false,
        :authors => ["jcran"],
        :description => "This strategy tries to enumerate assets with minimal interaction."
      }
    end

    def recurse(entity, task_result)
      puts "Recurse called for #{task_result.name} #{entity.name}... recursing"

      filter_strings = task_result.scan_result.whitelist_strings

      if entity.type_string == "DnsRecord"

        # get the domain length so we can see if this is a tld or internal name
        domain_length = (entity.name.split(".").length)

        # get the domain's base name (minus the TLD)
        base_name = entity.name.split(".")[0...-1].join(".")

        ### Permute the dns record to find similar entities
        if domain_length > 2
          start_recursive_task(task_result,"dns_permute", entity)
        end

        ### AWS_S3_brute the domain name and the base name
        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => "#{base_name}"}
        ])

        # Sublister API
        #if entity.name =~ /"#{filter_strings.join("|")}"/i
        #  start_recursive_task(task_result,"search_sublister", entity)
        #end

        # Threatcrowd API... skip resolutions, as we probably don't want old
        # data for this use case
        # and we should at least be of the form domain.something
        # (don't search for top level or unqual'd domains)
        #unless entity.name =~ /#{filter_strings.join("|")}/i && domain_length > 1
        #  start_recursive_task(task_result,"search_threatcrowd", entity, [
        #    {"name" => "gather_resolutions", "value" => true },
        #    {"name" => "gather_subdomains", "value" => true }])
        #send

        ### DNS Subdomain Bruteforce
        # Do a big bruteforce if the size is small enough
        if domain_length < 3

          start_recursive_task(task_result,"search_crt", entity,[
            {"name" => "extract_pattern", "value" => filter_strings.first }
          ])

          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true },
            {"name" => "threads", "value" => 1 }])

        else
          # otherwise do something a little faster
          if domain_length > 1 # don't bruteforce a tld
            start_recursive_task(task_result,"dns_brute_sub",entity,[])
          end
        end


      #elsif entity.type_string == "EmailAddress"
      #  # Search, only snag the top result
      #  start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      #elsif entity.type_string == "FtpService"
      #  start_recursive_task(task_result,"ftp_banner_grab",entity)

      elsif entity.type_string == "IpAddress"

        # Prevent us from hammering on whois services
        unless ( entity.created_by?("net_block_expand"))
          start_recursive_task(task_result,"whois",entity)
        end

        # Rather than scanning, let's use a service to look it up
        start_recursive_task(task_result,"search_shodan",entity)

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, expand it
        if entity.details["whois_full_text"] =~ /#{filter_strings.join("|")}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"net_block_expand",entity, [{"name" => "threads", "value" => 5 }])
        else
          task_result.log "Cowardly refusing to expand this netblock.. it doesn't look like ours."
        end

      elsif entity.type_string == "Person"
      #  # Search, only snag the top result
      #  start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      ### AWS_S3_brute the name
      start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "String"
        # Search, only snag the top result
        #start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

        ### AWS_S3_brute the name
        start_recursive_task(task_result,"aws_s3_brute",entity)

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
