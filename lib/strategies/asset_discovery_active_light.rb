module Intrigue
module Strategy
  class AssetDiscoveryActiveLight < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "asset_discovery_active_network",
        :pretty_name => "Asset Discovery (Active, Light)",
        :passive => false,
        :authors => ["jcran"],
        :description => "This strategy performs a light asset discovery. Start with a DnsRecord or NetBlock."
      }
    end

    def self.recurse(entity, task_result)

      filter_strings = "#{task_result.scan_result.filter_strings.gsub(",","|")}"

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
          {"name" => "additional_buckets", "value" => "#{base_name},#{entity.name}"}
        ])

        ### DNS Subdomain Bruteforce
        # Do a big bruteforce if the size is small enough
        if domain_length < 3

          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true },
            {"name" => "threads", "value" => 2 }])

        else
          # otherwise do something a little faster
          if domain_length > 1 # don't bruteforce a tld
            start_recursive_task(task_result,"dns_brute_sub",entity,[])
          end
        end

      elsif entity.type_string == "FtpService"
        start_recursive_task(task_result,"ftp_banner_grab",entity)

      elsif entity.type_string == "IpAddress"
        # Prevent us from hammering on whois services
        unless ( entity.created_by?("net_block_expand"))
          start_recursive_task(task_result,"whois",entity)
        end

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it. also skip ipv6/
        if entity.details["whois_full_text"] =~ /#{filter_strings}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"masscan_scan",entity,[{"name"=> "port", "value" => 80}])
          start_recursive_task(task_result,"masscan_scan",entity,[{"name"=> "port", "value" => 443}])
        else
          task_result.log "Cowardly refusing to scan this netblock.. it doesn't look like ours."
        end

        # Make sure it's small enough not to be disruptive, and if it is, expand it
        if entity.details["whois_full_text"] =~ /#{filter_strings}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"net_block_expand",entity, [{"name" => "threads", "value" => 5 }])
        else
          task_result.log "Cowardly refusing to expand this netblock.. it doesn't look like ours."
        end

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
