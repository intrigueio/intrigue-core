module Intrigue
module Machine
  class OrgAssetDiscoveryActive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "org_asset_discovery_active",
        :pretty_name => "Org Asset Data (Active)",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a recon and enumeration for an organization. Start with a Domain or NetBlock."
      }
    end

    # Recurse should receive a fully enriched object from the creator task
    def self.recurse(entity, task_result)

      project = entity.project
      seed_list = project.seeds.map{|s| s["name"]}.join(",")

      ### 
      # don't go any further unless we're scoped & not no-traverse (hidden)! 
      ### 
      traversable = false # default to no traverse
      traversable = true if entity.scoped # true if we're scoped and not hidden
      traversable = true if entity.type_string == "AwsS3Bucket" # allow these until scoping gets better
      traversable = true if entity.type_string == "AwsRegion" # allow these until scoping gets better
      traversable = true if entity.type_string == "DnsRecord" # allow these until scoping gets better
      traversable = true if entity.type_string == "EmailAddress" # allow these until scoping gets better
      traversable = true if entity.type_string == "GithubAccount" # allow these until scoping gets better
      traversable = true if entity.type_string == "IpAddress" # allow these until scoping gets better
      traversable = true if entity.type_string == "Organization" # allow these until scoping gets better
      traversable = true if entity.type_string == "NetworkService" # allow these until scoping gets better
      traversable = true if entity.type_string == "SslCertificate" # allow these until scoping gets better
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

      elsif entity.type_string == "AwsRegion" ## KINDA HAXXXY... TODO (remove & build a separate machine for these collections?)

        # test out a put file 
        start_recursive_task(task_result, "import/aws_ipv4_ranges", entity)

      elsif entity.type_string == "Domain"

        # get the nameservers
        start_recursive_task(task_result,"enumerate_nameservers", entity)

        #start_recursive_task(task_result,"security_trails_subdomain_search",entity, [], true)

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
        start_recursive_task(task_result,"dns_brute_sub_async",entity,[
          {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

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

      elsif entity.type_string == "EmailAddress"

        start_recursive_task(task_result,"search_have_i_been_pwned",entity,[])
        start_recursive_task(task_result,"saas_google_calendar_check",entity,[])

      elsif entity.type_string == "GithubAccount"

        #if entity.get_detail("account_type") == "Organization"
          start_recursive_task(task_result,"gitrob", entity, [])
        #end

      elsif entity.type_string == "IpAddress"
      
        # Prevent us from re-scanning services
        unless entity.created_by?("masscan_scan")
  
          ### search for netblocks
          start_recursive_task(task_result,"whois_lookup",entity, [])

          # scan if we haven't already hit the network range
          start_recursive_task(task_result,"nmap_scan",entity, [])
        end

      elsif entity.type_string == "Nameserver"

        start_recursive_task(task_result,"security_trails_nameserver_search",entity, [])

      elsif entity.type_string == "NetBlock"

        transferred = entity.get_detail("transferred")

        scannable = entity.scoped && !transferred

        task_result.log "#{entity.name} Enriched: #{entity.enriched}"
        task_result.log "#{entity.name} Scoped: #{entity.scoped}"
        task_result.log "#{entity.name} Transferred: #{transferred}"
        task_result.log "#{entity.name} Scannable: #{scannable}"

        # Make sure it's owned by the org, and if it is, scan it. also skip ipv6/
        if scannable

          start_recursive_task(task_result,"masscan_scan",entity,[
            {"name"=> "tcp_ports", "value" => "21,23,35,22,2222,5000,502,503,80,443,81,4786,8080,8081," + 
              "8443,3389,1883,8883,6379,6443,8032,9200,9201,9300,9301,9091,9092,9094,2181,2888,3888,5900," + 
              "5901,7001,27017,27018,27019,8278,8291"},
            {"name"=>"udp_ports", "value" => "161,1900"}])

        else
          task_result.log "Cowardly refusing to scan this netblock: #{entity}.. it's not scannable!"
        end

      elsif entity.type_string == "Organization"

        ### search for netblocks
        start_recursive_task(task_result,"whois_lookup",entity, [])

        # search bgp data for netblocks
        start_recursive_task(task_result,"search_bgp",entity, [], true)

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
        start_recursive_task(task_result,"uri_brute_focused_content", entity)

        start_recursive_task(task_result,"uri_check_subdomain_hijack",entity, [])


      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
