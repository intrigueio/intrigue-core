module Intrigue
module Strategy
  class OrgAssetDiscoveryActive < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "org_asset_discovery_active",
        :pretty_name => "Org Asset Discovery (Active)",
        :passive => false,
        :authors => ["jcran"],
        :description => "This strategy performs a network recon and enumeration for an organization. Suggest starting with a DnsRecord or NetBlock."
      }
    end

    def self.recurse(entity, task_result)

      filter_strings = "#{task_result.scan_result.filter_strings.gsub(",","|")}"

      if entity.type_string == "DnsRecord"

        domain_length = (entity.name.split(".").length)       # get the domain length so we can see if this is a tld or internal name
        base_name = entity.name.split(".")[0...-1].join(".")  # get the domain's base name (minus the TLD)

        ### Permute the dns record to find similar entities
        if domain_length > 2
          start_recursive_task(task_result,"dns_permute", entity)
        end

        ### AWS_S3_brute the domain name and the base name
        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => "#{base_name},#{entity.name}"}
        ])

        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "threads", "value" => 2 }])

      elsif entity.type_string == "FtpService"
        start_recursive_task(task_result,"ftp_enumerate",entity)

      elsif entity.type_string == "IpAddress"

        start_recursive_task(task_result,"masscan_scan",entity,[{"name"=> "ports", "value" => "21,80,443"}])

      elsif entity.type_string == "NetBlock"

        # Make sure it's owned by the org, and if it is, scan it. also skip ipv6/
        if entity.details["whois_full_text"] =~ /#{filter_strings}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"masscan_scan",entity,[{"name"=> "ports", "value" => "21,80,443"}])
        else
          task_result.log "Cowardly refusing to scan this netblock.. it doesn't look like ours."
        end

        # Make sure it's small enough not to be disruptive, and if it is, expand it
        if entity.details["whois_full_text"] =~ /#{filter_strings}/i && !(entity.name =~ /::/)
          start_recursive_task(task_result,"net_block_expand",entity, [{"name" => "threads", "value" => 5 }])
        else
          task_result.log "Cowardly refusing to expand this netblock.. it doesn't look like ours."
        end

      elsif entity.type_string == "Person"

      ### AWS_S3_brute the name
      start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "String"

        ### AWS_S3_brute the name
        start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "Uri"

        # Check for exploitable URIs, but don't recurse on things we've already found
        start_recursive_task(task_result,"uri_brute", entity, [
          {"name"=> "threads", "value" => 1},
          {"name" => "user_list", "value" => "admin,test,server-status,.svn,.git"}])

        unless (entity.created_by?("uri_brute") || entity.created_by?("uri_spider") )

          ## Grab the SSL Certificate
          start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

          ## Super-lite spider, looking for metadata
          start_recursive_task(task_result,"uri_spider",entity,[
              {"name" => "max_pages", "value" => 50 },
              {"name" => "extract_dns_records", "value" => true },
              {"name" => "extract_dns_record_pattern", "value" => "#{filter_strings}"}])
        end
      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
