module Intrigue
module Strategy
  class Default < Intrigue::Strategy::Base

    def self.recurse(entity, task_result)

      if entity.type_string == "DnsRecord"

        start_recursive_task(task_result,"nmap_scan",entity)

        ### DNS Forward Lookup
        start_recursive_task(task_result, "get_alternate_names", entity)

        ### DNS Subdomain Bruteforce
        # Do a big bruteforce if the size is small enough
        if (entity.name.split(".").length < 3)
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => true },
            {"name" => "brute_alphanumeric_size", "value" => 3},
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false },
            {"name" => "threads", "value" => 1 }])
        else
          # otherwise do something a little faster
          start_recursive_task(task_result,"dns_brute_sub",entity,[
            {"name" => "use_file", "value" => false },
            {"name" => "use_permutations", "value" => true },
            {"name" => "use_mashed_domains", "value" => false },
            {"name" => "threads", "value" => 1 }])
        end

      elsif entity.type_string == "String"

        # Search, only snag the top result
        start_recursive_task(task_result,"search_bing",entity,[{"name"=> "max_results", "value" => 1}])

      elsif entity.type_string == "IpAddress"

        ### DNS Reverse Lookup
        start_recursive_task(task_result, "get_alternate_names", entity)

        ### Scan
        start_recursive_task(task_result,"nmap_scan",entity)

        ### Whois
        start_recursive_task(task_result,"whois",entity)

      elsif entity.type_string == "NetBlock"

        # Make sure it's small enough not to be disruptive, and if it is, scan it
        cidr = entity.name.split("/").last.to_i
        if cidr >= 24
          start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 80}])
          start_recursive_task(task_result,"masscan_scan",entity, [{"port" => 443}])
        end

      elsif entity.type_string == "Uri"

        ## Grab the Web Server

        ## Grab the SSL Certificate
        start_recursive_task(task_result,"uri_gather_ssl_certificate",entity) if entity.name =~ /^https/

        ## Spider, looking for metadata
        start_recursive_task(task_result,"uri_spider",entity,[
            {"name" => "threads", "value" => 1},
            {"name" => "max_pages", "value" => 1000},
            {"name" => "extract_dns_records", "value" => true},
            {"name" => "extract_dns_record_pattern", "value" => "#{task_result.scan_result.base_entity.name}"}]) unless entity.created_by? "uri_brute"

        # Check for exploitable URIs, but don't recurse on things we've already found
        start_recursive_task(task_result,"uri_brute", entity, [{"name"=> "threads", "value" => 1}, {"name" => "user_list", "value" => "admin"}]) unless entity.created_by? "uri_brute"

      else
        puts "No actions for entity: #{entity.type}##{entity.details["name"]}"
        return
      end
    end

end
end
end
