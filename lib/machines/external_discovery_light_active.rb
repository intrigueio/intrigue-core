module Intrigue
module Machine
  class ExternalDiscoveryLightActive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "external_discovery_light_active",
        :pretty_name => "External Discovery - Light, Active",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a light active enumeration. Start with a Domain or NetBlock."
      }
    end

      # Used in the machines
      def self.get_task_config(key)
        begin
          Intrigue::Core::System::Config.load_config
          config = Intrigue::Core::System::Config.config["intrigue_global_module_config"]
          value = config[key]["value"]
        rescue NoMethodError => e
          _log "Error, invalid config key requested (#{key}) #{e}"
          return nil
        end
      value
      end
  
      # Recurse should receive a fully enriched object from the creator task
      def self.recurse(entity, task_result)
  
        project = entity.project
        return unless project
  
        seed_list = project.seeds.map{|s| s.name }.join(",")
  
        ###
        # Don't go any further unless we're scoped!
        ###
        return unless entity.scoped?
  
        if entity.type_string == "AwsS3Bucket"
  
          # test out a put file
          start_recursive_task(task_result, "aws_s3_put_file", entity)
  
        elsif entity.type_string == "Domain"
  
          # get the nameservers
          start_recursive_task(task_result,"enumerate_nameservers", entity)
  
          # try an nsec walk
          #start_recursive_task(task_result,"dns_nsec_walk", entity ,[], true)
  
          # attempt a zone transfer
          start_recursive_task(task_result,"dns_transfer_zone", entity, [], true)
  
          # look up and store dkim records, and a domain so we can associate the org
          start_recursive_task(task_result,"dns_lookup_dkim", entity ,[
            {"name" => "create_domain", "value" => true }])
  
          # get subdomains from security trails
          # start_recursive_task(task_result,"security_trails_subdomain_search", entity)
  
          # check certificate records
          start_recursive_task(task_result,"search_crt", entity,[
            {"name" => "extract_pattern", "value" => seed_list }])
  
          # check certspotter for more certificates
          start_recursive_task(task_result,"search_certspotter", entity,[
            {"name" => "extract_pattern", "value" => seed_list }])
  
          # search tls cert results
          start_recursive_task(task_result,"dns_search_tls_cert_names", entity, [], true)

          # search sonar results
          start_recursive_task(task_result,"dns_search_sonar",entity, true) 

          # threatcrowd
          start_recursive_task(task_result,"search_threatcrowd", entity,[], true)
  
          # search recon.dev
          start_recursive_task(task_result,"search_recon_dev",entity, []) 

          # bruteforce email addresses
          start_recursive_task(task_result,"email_brute_gmail_glxu",entity,[], true)
  
          # quick spf recurse, creating new (unscoped) domains
          start_recursive_task(task_result,"dns_recurse_spf",entity, [])
  
          # run dns-morph, if the length of the domain is sufficent
          if entity.name.length > 3
            start_recursive_task(task_result,"dns_morph", entity,[])
          end
  
          # quick subdomain bruteforce
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "brute_alphanumeric_size", "value" => 1 },
            {"name" => "use_file", "value" => true }], true)
  
          #start_recursive_task(task_result,"saas_trello_check",entity,[])
          start_recursive_task(task_result,"saas_jira_check",entity,[])
    
          start_recursive_task(task_result,"vuln/saas_google_groups_check",entity,[])
          start_recursive_task(task_result,"vuln/saas_google_calendar_check",entity,[])
  
        elsif entity.type_string == "DnsRecord"
  
          # Check for malciousness
          #start_recursive_task(task_result,"threat/search_cleanbrowsing_dns", entity, [])
          #start_recursive_task(task_result,"threat/search_comodo_dns", entity, [])
          start_recursive_task(task_result,"threat/search_opendns", entity, [])
          #start_recursive_task(task_result,"threat/search_quad9_dns", entity, [])
          #start_recursive_task(task_result,"threat/search_yandex_dns", entity, [])
  
        elsif entity.type_string == "EmailAddress"
  
          #start_recursive_task(task_result,"search_have_i_been_pwned",entity,[
          #  {"name" => "only_sensitive", "value" => true }])
  
          start_recursive_task(task_result,"vuln/saas_google_calendar_check",entity,[])
  
        elsif entity.type_string == "GithubAccount"
  
          start_recursive_task(task_result,"gitrob", entity, [])
  
        elsif entity.type_string == "IpAddress"
  
          # Prevent us from re-scanning services
          unless entity.created_by?("masscan_scan")
  
            ### search for netblocks
            start_recursive_task(task_result,"whois_lookup",entity, [])
  
            # and we might as well scan to cover any new info
            start_recursive_task(task_result,"naabu_scan",entity, [])
          end
    
        elsif entity.type_string == "NetBlock"
  
          transferred = entity.get_detail("transferred")
  
          scannable = entity.scoped && !transferred
  
          # Make sure it's owned by the org, and if it is, scan it. also skip ipv6/
          if scannable
  
            # 17185 - vxworks
            # https://duo.com/decipher/mapping-the-internet-whos-who-part-three
  
            start_recursive_task(task_result,"masscan_scan",entity,[
              {"name"=> "tcp_ports", "value" => scannable_tcp_ports.join(",") },
              {"name"=>"udp_ports", "value" => scannable_udp_ports.join(",") }])
  
          else
            task_result.log "Cowardly refusing to scan this netblock: #{entity}.. it's not scannable!"
          end
  
        elsif entity.type_string == "NetworkService"

          # run a traceroute
          start_recursive_task(task_result,"tcp_traceroute",entity, [])
  
        elsif entity.type_string == "Organization"
  
          ### search for netblocks
          start_recursive_task(task_result,"whois_lookup",entity, [])
  
          # search bgp data for netblocks
          start_recursive_task(task_result,"search_bgp",entity, [], true)
    
          # Search for jira accounts
          start_recursive_task(task_result,"saas_jira_check",entity)
  
          # Search for other accounts with this name
          start_recursive_task(task_result,"web_account_check",entity)
  
        elsif entity.type_string == "Uri"
  
          puts "Working on URI #{entity.name}!"
  
          # run a traceroute
          start_recursive_task(task_result,"tcp_traceroute",entity, [])
  
          ## Grab the SSL Certificate
          start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, []) if entity.name =~ /^https/
  
          # check api endpoint 
          start_recursive_task(task_result,"uri_check_api_endpoint",entity, [])

          # check http2 
          start_recursive_task(task_result,"uri_check_http2_support",entity, [])
          
          start_recursive_task(task_result,"uri_brute_generic_content",entity, [])

          start_recursive_task(task_result,"uri_extract_tokens",entity, [])

          # extract links 
          start_recursive_task(task_result,"uri_extract_linked_hosts",entity, []) 

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
