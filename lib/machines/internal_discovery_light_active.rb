module Intrigue
module Machine
  class InternalDiscoveryLightActive < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "internal_light_discovery_active",
        :pretty_name => "Internal Discovery - Light, Active",
        :passive => false,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine performs a light enumeration on an internal network. Start with a Domain or NetBlock."
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

      if entity.type_string == "AwsS3Bucket"
        
        # test out a put file 
        start_recursive_task(task_result, "aws_s3_put_file", entity)

      elsif entity.type_string == "Domain"

        # get the nameservers
        start_recursive_task(task_result,"enumerate_nameservers", entity)

        # attempt a zone transfer
        start_recursive_task(task_result,"dns_transfer_zone", entity, [], true)

        # check certificate records
        start_recursive_task(task_result,"search_crt", entity,[
          {"name" => "extract_pattern", "value" => seed_list }])

        # check certspotter for more certificates
        start_recursive_task(task_result,"search_certspotter", entity,[
          {"name" => "extract_pattern", "value" => seed_list }])

        # quick subdomain bruteforce
        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

      elsif entity.type_string == "DnsRecord"

        # quick subdomain bruteforce
        start_recursive_task(task_result,"dns_brute_sub",entity,[
          {"name" => "brute_alphanumeric_size", "value" => 1 }], true)

      elsif entity.type_string == "IpAddress"
      
        # Prevent us from re-scanning services
        unless entity.created_by?("masscan_scan")
          # and we might as well scan to cover any new info
          start_recursive_task(task_result,"nmap_scan",entity, [])
        end

      elsif entity.type_string == "NetBlock"

        start_recursive_task(task_result,"masscan_scan",entity,[
          {"name"=> "tcp_ports", "value" => "21,23,35,22,2222,5000,502,503,80,443,81,4786,8080,8081," + 
            "8443,3389,1883,8883,6379,6443,8032,9200,9201,9300,9301,9091,9092,9094,2181,2888,3888,5900," + 
            "5901,7001,27017,27018,27019,8278,8291,53413,9000,11994"},
          {"name"=>"udp_ports", "value" => "123,161,1900,17185"}])

      elsif entity.type_string == "NetworkService"

        #if entity.get_detail("service") == "RDP"
        #  start_recursive_task(task_result,"rdpscan_scan",entity, [], true)
        #end

      elsif entity.type_string == "Uri"

        # wordpress specific checks
        if entity.get_detail("fingerprint")

          if entity.get_detail("fingerprint").any?{|v| v['product'] =~ /Wordpress/i }
            puts "Checking Wordpress specifics on #{entity.name}!"
            start_recursive_task(task_result,"wordpress_enumerate_users",entity, [])
            start_recursive_task(task_result,"wordpress_enumerate_plugins",entity, [])
          end

          if entity.get_detail("fingerprint").any?{|v| v['product'] =~ /GlobalProtect/ }
            puts "Checking GlobalProtect specifics on #{entity.name}!"
            start_recursive_task(task_result,"vuln/globalprotect_check",entity, [])
          end

          # Hold on this for now, memory leak?
          #if entity.get_detail("fingerprint").any?{|v| v['vendor'] == "Apache" && v["product"] == "HTTP Server" }
          #  start_recursive_task(task_result,"apache_server_status_parser",entity, [])
          #end

        end

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, []) if entity.name =~ /^https/

        # Check for exploitable URIs, but don't recurse on things we've already found
        #unless (entity.created_by?("uri_brute_focused_content") || entity.created_by?("uri_spider") )
        start_recursive_task(task_result,"uri_brute_focused_content", entity)
        #end
        

        # if we're going deeper 
        unless entity.created_by?("uri_spider")
          # Super-lite spider, looking for metadata
          start_recursive_task(task_result,"uri_spider",entity,[
            {"name" => "max_pages", "value" => 100 },
            {"name" => "extract_dns_records", "value" => true }
          ])
        end

      else
        task_result.log "No actions for entity type: #{entity.type}"
        return
      end

    end

end
end
end
