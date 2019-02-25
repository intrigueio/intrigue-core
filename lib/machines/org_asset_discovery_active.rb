module Intrigue
module Machine
  class OrgAssetDiscoveryActive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "org_asset_discovery_active",
        :pretty_name => "Org Asset Discovery (Active)",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a network recon and enumeration for an organization. Start with a Domain or NetBlock. No credentials required."
      }
    end

    # Recurse should receive a fully enriched object from the creator task
    def self.recurse(entity, task_result)

      filter_strings = task_result.scan_result.whitelist_strings

      if entity.type_string == "Domain"

        # only applicable to dns_record, domain, and netblock for now
        # whitelisted still checks project name, so leave it for now
        inferred_whitelist = "#{entity.get_detail("whois_full_text")}".downcase =~ /#{filter_strings.map{|x| Regexp.escape(x.downcase) }.join("|")}/i

        return unless (entity.scoped || inferred_whitelist )

        # requires better key management before we can enable by default
        #start_recursive_task(task_result,"security_trails_subdomain_search",entity, [], true)

        # get the nameservers, so we can go further
        start_recursive_task(task_result,"enumerate_nameservers", entity)

        start_recursive_task(task_result,"search_crt", entity,[
          {"name" => "extract_pattern", "value" => filter_strings.first}], true)

        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "threads", "value" => 10 },
          {"name" => "use_file", "value" => true },
          {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

        start_recursive_task(task_result,"saas_trello_check",entity)
        start_recursive_task(task_result,"saas_google_groups_check", entity)

        # GITHUB!

        base_name = entity.name.split(".")[0...-1].join(".")
        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => "#{base_name},#{entity.name}"}
        ])

      elsif entity.type_string == "DnsRecord"

        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "threads", "value" => 5 }])

      elsif entity.type_string == "FtpService"

        start_recursive_task(task_result,"ftp_enumerate",entity, [], true)

      elsif entity.type_string == "IpAddress"

        # Prevent us from hammering on whois services
        unless entity.get_detail("whois_full_text")
          start_recursive_task(task_result,"whois_lookup",entity)
        end

        # Prevent us from re-scanning services
        unless entity.created_by?("masscan_scan")
          start_recursive_task(task_result,"nmap_scan",entity, [], true)
        end

      elsif entity.type_string == "Nameserver"

        inferred_whitelist = ("#{entity.name}" =~ /#{filter_strings.map{|x| Regexp.escape(x.downcase) }.join("|")}/i)

        return unless (entity.scoped || inferred_whitelist )

        # requires better key management before we can enable by default
        #start_recursive_task(task_result,"security_trails_nameserver_search",entity, [], true)

      elsif entity.type_string == "NetBlock"

        # only applicable to dns_record, domain, and netblock for now
        # whitelisted still checks project name, so leave it for now
        inferred_whitelist = "#{entity.get_detail("whois_full_text")}".downcase =~ /#{filter_strings.map{|x| Regexp.escape(x.downcase) }.join("|")}/i

        transferred = entity.get_detail("transferred")

        scannable = ( entity.scoped || inferred_whitelist ) && !transferred

        task_result.log "#{entity.name} Enriched: #{entity.enriched}"
        task_result.log "#{entity.name} Scoped: #{entity.scoped}"
        task_result.log "#{entity.name} Whitelisted: #{inferred_whitelist}"
        task_result.log "#{entity.name} Transferred: #{transferred}"
        task_result.log "#{entity.name} Scannable: #{scannable}"

        # Make sure it's owned by the org, and if it is, scan it. also skip ipv6/
        if scannable
          # Muhstik seems like a pretty good baseline for this stuff
          # 80/443: Weblogic, Wordpress, Drupal, WebDav, ClipBucket
          # 2004: Webuzo
          # 7001: Weblogic
          # 8080: Wordpress, WebDav, DasanNetwork Solution
          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => ""},
            {"name"=>"udp_ports", "value" => "161"}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "22"},
            {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "23"},
            {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "25"},
            {"name"=>"udp_ports", "value" => ""}])

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "80"},
            {"name"=>"udp_ports", "value" => ""}], true)

          #start_recursive_task(task_result,"masscan_scan",entity,[
          #  {"name"=> "tcp_ports", "value" => "81"},
          #  {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "3389"},
            {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "8080"},
            {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "8081"},
            {"name"=>"udp_ports", "value" => ""}], true)

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "8443"},
            {"name"=>"udp_ports", "value" => ""}], true)

          #start_recursive_task(task_result,"masscan_scan",entity,[
          #  {"name"=> "tcp_ports", "value" => "10000"},
          #  {"name"=>"udp_ports", "value" => ""}], true)

        else
          task_result.log "Cowardly refusing to scan this netblock: #{entity}.. it doesn't look like ours."
        end

      elsif entity.type_string == "Organization"

      ### search for netblocks
      start_recursive_task(task_result,"whois_lookup",entity, [], true)

      # search bgp data for netblocks
      start_recursive_task(task_result,"search_bgp",entity, [], true)

      #
      start_recursive_task(task_result,"saas_trello_check",entity)

      ### AWS_S3_brute the name
      start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "Person"

      ### AWS_S3_brute the name
      start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "String"

        ### AWS_S3_brute the name
        start_recursive_task(task_result,"aws_s3_brute",entity)

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, [],  true) if entity.name =~ /^https/

        # Check for exploitable URIs, but don't recurse on things we've already found
        unless (entity.created_by?("uri_brute_focused_content") || entity.created_by?("uri_spider") )
          start_recursive_task(task_result,"uri_brute_focused_content", entity)
        end

        #unless (entity.created_by?("uri_brute") || entity.created_by?("uri_spider") )
          ## Super-lite spider, looking for metadata
          #start_recursive_task(task_result,"uri_spider",entity,[
          #    {"name" => "max_pages", "value" => 10 },
          #    {"name" => "extract_dns_records", "value" => true },
          #    {"name" => "extract_dns_record_pattern", "value" => "#{filter_strings.first}"}])
        #end

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
