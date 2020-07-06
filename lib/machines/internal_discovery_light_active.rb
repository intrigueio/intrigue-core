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
          # and we might as well scan to cover any new info
          start_recursive_task(task_result,"naabu_scan",entity, [
            {"name"=> "tcp_ports", "value" => scannable_tcp_ports},
            {"name"=> "udp_ports", "value" => scannable_udp_ports}])
        end

      elsif entity.type_string == "NetBlock"

        start_recursive_task(task_result,"masscan_scan",entity,[
          {"name"=> "tcp_ports", "value" => scannable_tcp_ports},
          {"name"=> "udp_ports", "value" => scannable_udp_ports}])

      elsif entity.type_string == "NetworkService"

      elsif entity.type_string == "Uri"

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity, []) if entity.name =~ /^https/

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
