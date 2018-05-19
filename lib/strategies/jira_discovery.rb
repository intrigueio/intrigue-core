module Intrigue
module Strategy
  class JiraDiscovery < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "jira_discovery",
        :pretty_name => "Jira Discovery",
        :passive => false,
        :authors => ["jcran"],
	      :description => "jira discovery one-off"
      }
    end

    def self.recurse(entity, task_result)

      filter_strings = "#{task_result.scan_result.filter_strings.gsub(",","|")}"

      if entity.type_string == "DnsRecord"

        domain_length = (entity.name.split(".").length)       # get the domain length so we can see if this is a tld or internal name
        base_name = entity.name.split(".")[0...-1].join(".")  # get the domain's base name (minus the TLD)

	      if entity.name =~/jira/ || entity.name =~ /confluence/
	          start_recursive_task(task_result,"enrich/dns_record",entity)
        end

      elsif entity.type_string == "IpAddress"

        start_recursive_task(task_result,"nmap_scan",entity)

      elsif entity.type_string == "Uri"

        start_recursive_task(task_result,"enrich/uri",entity)
        start_recursive_task(task_result,"enrich/web_stack_fingerprint",entity)

      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end
    end

end
end
end
