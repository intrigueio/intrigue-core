module Intrigue
module Machine
  class ExternalDiscoveryLightPassive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "external_discovery_light_passive",
        :pretty_name => "External Discovery - Light, Passive",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a light passive enumeration. Start with a Domain or NetBlock."
      }
    end

    # Recurse should receive a fully enriched object from the creator task
    def self.recurse(entity, task_result)

      project = entity.project
      seed_list = project.seeds.map{|s| s.name }.join(",")

      ### 
      # Don't go any further unless we're scoped! 
      ### 
      traversable = false # default to no traverse
      # This is a little trixy, allows for runtime scoping since we're dynamically checking
      traversable = true if entity.scoped? && !entity.hidden # true if we're scoped and not hidden      
      # LOG THE CHOICE
      return unless traversable 
      ###
      #  End scoping madness 
      ###

      if entity.type_string == "Domain"

        # get the nameservers
        start_recursive_task(task_result,"enumerate_nameservers", entity)

        # attempt a zone transfer.. unlikely to be noticed, so allowing
        start_recursive_task(task_result,"dns_transfer_zone", entity, [], true)

        # check certificate records
        start_recursive_task(task_result,"search_crt", entity,[
          {"name" => "extract_pattern", "value" => seed_list }])

        # check certspotter for more certificates
        start_recursive_task(task_result,"search_certspotter", entity,[
          {"name" => "extract_pattern", "value" => seed_list }])

        # search sonar results
        start_recursive_task(task_result,"dns_search_sonar",entity, [], true)

        # threatcrowd 
        start_recursive_task(task_result,"search_threatcrowd", entity,[], true)

        # bruteforce email addresses
        start_recursive_task(task_result,"email_brute_gmail_glxu",entity,[], true)

        # quick spf recurse, creating new (unscoped) domains 
        start_recursive_task(task_result,"dns_recurse_spf",entity, [])

        # run dnsmorph, looking for permutations
        start_recursive_task(task_result,"dns_morph", entity,[])

        # quick subdomain bruteforce
        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

        
        #start_recursive_task(task_result,"saas_trello_check",entity,[])
        start_recursive_task(task_result,"saas_jira_check",entity,[])

        # search greyhat warfare
        start_recursive_task(task_result,"search_grayhat_warfare",entity, [], true)

        # S3 bruting based on domain name
       #generated_names = [
       #   "#{entity.name.split(".").join("")}",
       #   "#{entity.name.split(".").join("-")}",
       #   "#{entity.name.split(".").join("_")}",
       #   "#{entity.name.split(".")[0...-1].join(".")}",
       #   "#{entity.name.split(".")[0...-1].join("")}",
       #   "#{entity.name.split(".")[0...-1].join("_")}",
       #   "#{entity.name.split(".")[0...-1].join("-")}",
       #   "#{entity.name.gsub(" ","")}"
       # ]

       # start_recursive_task(task_result,"aws_s3_brute",entity,[
       #   {"name" => "use_creds", "value" => true},
       #   {"name" => "additional_buckets", "value" => generated_names.join(",")}])
        
       start_recursive_task(task_result,"vuln/saas_google_groups_check",entity,[])
       start_recursive_task(task_result,"vuln/saas_google_calendar_check",entity,[])

      elsif entity.type_string == "DnsRecord"

        #start_recursive_task(task_result,"dns_brute_sub",entity)

      elsif entity.type_string == "EmailAddress"

        start_recursive_task(task_result,"search_have_i_been_pwned",entity,[
          {"name" => "only_sensitive", "value" => true }])
  
        start_recursive_task(task_result,"vuln/saas_google_calendar_check",entity,[])

      elsif entity.type_string == "GithubAccount"

        start_recursive_task(task_result,"gitrob", entity, [])

      elsif entity.type_string == "IpAddress"
      
        ### search for netblocks
        start_recursive_task(task_result,"whois_lookup",entity, [])

        # use shodan to "scan" and create ports 
        start_recursive_task(task_result,"search_shodan",entity, [])
        
        # use shodan to "scan" and create ports 
        start_recursive_task(task_result,"search_censys",entity, [])

        # use shodan to "scan" and create ports 
        start_recursive_task(task_result,"search_binaryedge",entity, [])

      elsif entity.type_string == "Nameserver"

        start_recursive_task(task_result,"security_trails_nameserver_search",entity, [], true)

      elsif entity.type_string == "NetBlock"

        transferred = entity.get_detail("transferred")

        scannable = entity.scoped && !transferred

        task_result.log "#{entity.name} Enriched: #{entity.enriched}"
        task_result.log "#{entity.name} Scoped: #{entity.scoped}"
        task_result.log "#{entity.name} Transferred: #{transferred}"
        task_result.log "#{entity.name} Scannable: #{scannable}"

        # Make sure it's owned by the org, and if it is, scan it. also skip ipv6/
        if scannable

          # so this could use up a lot of shodan credits, just be aware. 
          start_recursive_task(task_result,"net_block_expand",entity, [])

        else
          task_result.log "Cowardly refusing to scan this netblock: #{entity}.. it's not scannable!"
        end

      elsif entity.type_string == "Organization"

        ### search for netblocks
        start_recursive_task(task_result,"whois_lookup",entity, [])

        # search bgp data for netblocks
        start_recursive_task(task_result,"search_bgp",entity, [], true)

        # search greyhat warfare
        start_recursive_task(task_result,"search_grayhat_warfare",entity, [], true)

        # Search for jira accounts
        start_recursive_task(task_result,"saas_jira_check",entity)

        # Search for other accounts with this name
        start_recursive_task(task_result,"web_account_check",entity)

        # Search for trello accounts - currently requires browser
        #start_recursive_task(task_result,"saas_trello_check",entity)

        ### search for github - too noisy? 
        #start_recursive_task(task_result,"search_github",entity, [], true)

        ### AWS_S3_brute the name
        # S3!
        generated_names = [
          "#{entity.name.gsub(" ","")}",
          "#{entity.name.gsub(" ","-")}",
          "#{entity.name.gsub(" ","_")}"
        ]

        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => generated_names.join(",")}])

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, []) if entity.name =~ /^https/

        if entity.name =~ (ipv4_regex || ipv6_regex)
          puts "Cowardly refusing to check for subdomain hijack, #{entity.name} looks like an access-by-ip uri"
        else 
          start_recursive_task(task_result,"uri_check_subdomain_hijack",entity, [])
        end

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
