module Intrigue
module Machine
  class OrgAssetDiscoveryPassive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "org_asset_discovery_passive",
        :pretty_name => "Org Asset Data (Passive)",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a recon and enumeration for an organization" +
                        "using only passive sources. Start with a Domain or NetBlock."
      }
    end

    # Recurse should receive a fully enriched object from the creator task
    def self.recurse(entity, task_result)

      seed_list = entity.project.seeds.map{|s| s["name"]}.join(",")

      ### 
      # don't go any further unless we're scoped & not no-traverse (hidden)! 
      ### 
      traversable = false # default to no traverse
      traversable = true if entity.scoped # true if we're scoped and not hidden
      traversable = true if entity.type_string == "AwsS3Bucket" # allow these until scoping gets better
      traversable = true if entity.type_string == "AwsRegion" # allow these until scoping gets better
      traversable = true if entity.type_string == "DnsRecord" # allow these until scoping gets better
      traversable = true if entity.type_string == "EmailAddress" # allow these until scoping gets better
      traversable = true if entity.type_string == "IpAddress" # allow these until scoping gets better
      traversable = true if entity.type_string == "Organization" # allow these until scoping gets better
      traversable = true if entity.type_string == "NetworkService" # allow these until scoping gets better
      traversable = true if entity.type_string == "String" # allow these until scoping gets better
      traversable = true if entity.type_string == "Uri" # allow these until scoping gets better
      traversable = false if entity.hidden # always skip hiddens (implicitly non-traversable)
      
      # LOG THE CHOICE
      if traversable 
        puts "#{entity.type_string} #{entity.name} traversable!!"
      else
        puts "#{entity.type_string} #{entity.name} NOT traversable!!" 
        return
      end

      if entity.type_string == "AwsS3Bucket"
        
        # test out a put file 
        start_recursive_task(task_result, "aws_s3_put_file", entity)

      elsif entity.type_string == "Domain"

        # get the nameservers
        start_recursive_task(task_result,"enumerate_nameservers", entity)

        # try an nsec walk
        start_recursive_task(task_result,"dns_nsec_walk", entity ,[])

        # attempt a zone transfer
        start_recursive_task(task_result,"dns_transfer_zone", entity, [])

        # check certificate records
        start_recursive_task(task_result,"search_crt", entity,[
          {"name" => "extract_pattern", "value" => seed_list }])

        # search sonar results
        start_recursive_task(task_result,"dns_search_sonar",entity, [])

        # threatcrowd 
        start_recursive_task(task_result,"search_threatcrowd", entity,[])

        # bruteforce email addresses
        start_recursive_task(task_result,"email_brute_gmail_glxu",entity,[])

        # subdomain bruteforce
        #start_recursive_task(task_result,"dns_brute_sub_async",entity,[
        #  {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

        start_recursive_task(task_result,"saas_google_groups_check",entity,[])
        start_recursive_task(task_result,"saas_trello_check",entity,[])
        start_recursive_task(task_result,"saas_jira_check",entity,[])

        # S3 bruting based on domain name
       generated_names = [
          "#{entity.name.split(".").join("")}",
          "#{entity.name.split(".").join("-")}",
          "#{entity.name.split(".").join("_")}",
          "#{entity.name.split(".")[0...-1].join(".")}",
          "#{entity.name.split(".")[0...-1].join("")}",
          "#{entity.name.split(".")[0...-1].join("_")}",
          "#{entity.name.split(".")[0...-1].join("-")}",
          "#{entity.name.gsub(" ","")}"
        ]

        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => generated_names.join(",")}])

      elsif entity.type_string == "DnsRecord"

        # search sonar results
        start_recursive_task(task_result,"dns_search_sonar",entity, [])

        #start_recursive_task(task_result,"dns_brute_sub_async",entity)

      elsif entity.type_string == "EmailAddress"

        start_recursive_task(task_result,"search_have_i_been_pwned",entity,[])
        start_recursive_task(task_result,"saas_google_calendar_check",entity,[])

      elsif entity.type_string == "GithubAccount"

        #if entity.get_detail("account_type") == "Organization"
          start_recursive_task(task_result,"gitrob", entity, [])
        #end

      elsif entity.type_string == "IpAddress"

        ### search for netblocks
        start_recursive_task(task_result,"whois_lookup",entity, [])

        # Prevent us from re-scanning services
        #unless entity.created_by?("masscan_scan")
        #  start_recursive_task(task_result,"nmap_scan",entity, [])
        #ends

        start_recursive_task(task_result,"search_shodan",entity, [])
        start_recursive_task(task_result,"search_censys",entity, [])
        start_recursive_task(task_result,"search_binary_edge",entity, [])

      elsif entity.type_string == "Nameserver"

        start_recursive_task(task_result,"security_trails_nameserver_search",entity, [])

      elsif entity.type_string == "NetBlock"

        transferred = entity.get_detail("transferred")

        start_recursive_task(task_result,"net_block_expand",entity, [])
     
      elsif entity.type_string == "Organization"

        ### search for netblocks
        start_recursive_task(task_result,"whois_lookup",entity, [])

        # search bgp data for netblocks
        start_recursive_task(task_result,"search_bgp",entity, [], true)

        ### search github
        start_recursive_task(task_result,"search_github",entity, [])

        # Search for trello accounts
        start_recursive_task(task_result,"saas_trello_check",entity)

        # Search for jira accounts
        start_recursive_task(task_result,"saas_jira_check",entity)

        ### AWS_S3_brute the name
        # S3!
        generated_names = [
          "#{entity.name.gsub(" ","")}",
          "#{entity.name.gsub(" ","-")}",
          "#{entity.name.gsub(" ","_")}"
        ]

        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => generated_names.join(",")}])


      elsif entity.type_string == "Person"

        ### AWS_S3_brute the name
        # S3!
        generated_names = [
          "#{entity.name.gsub(" ","")}",
          "#{entity.name.gsub(" ","-")}",
          "#{entity.name.gsub(" ","_")}"
        ]

        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => generated_names.join(",")}])

      elsif entity.type_string == "String"

        ### AWS_S3_brute the name
        # S3!
        generated_names = [
          "#{entity.name.split(".").join("")}",
          "#{entity.name.split(".").join("-")}",
          "#{entity.name.split(".").join("_")}",
          "#{entity.name.gsub(" ","")}"
        ]

        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets", "value" => generated_names.join(",")}])

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, []) if entity.name =~ /^https/

        # Check for exploitable URIs, but don't recurse on things we've already found
        #unless (entity.created_by?("uri_brute_focused_content") || entity.created_by?("uri_spider") )
        #start_recursive_task(task_result,"uri_brute_focused_content", entity)
        #end

        start_recursive_task(task_result,"uri_check_subdomain_hijack",entity, [])

        # Check for exploitable URIs, but don't recurse on things we've already found
        #start_recursive_task(task_result,"uri_brute", entity, [
        #  {"name"=> "threads", "value" => 1},
        #  {"name" => "user_list", "value" => "reports,portal,admin,test,server-status,.svn,.git"}])

        #unless (entity.created_by?("uri_brute") || entity.created_by?("uri_spider") )
          ## Super-lite spider, looking for metadata
          #start_recursive_task(task_result,"uri_spider",entity,[
          #    {"name" => "max_pages", "value" => 10 },
          #    {"name" => "extract_dns_records", "value" => true }
          # ])
        #end

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
