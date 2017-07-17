module Intrigue
module Strategy
  class DomainIntel < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "domain_intel",
        :pretty_name => "Domain Intel",
        :authors => ["jcran"],
        :description => "This strategy looks up entities in whois."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "DnsRecord"
        start_recursive_task(task_result,"whois",entity) unless entity.created_by?("whois")
      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end

    end

end
end
end
