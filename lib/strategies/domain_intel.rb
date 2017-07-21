module Intrigue
module Strategy
  class DomainIntel < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "domain_intel",
        :pretty_name => "Domain Intel",
        :authors => ["jcran"],
        :description => "This strategy grabs the source ."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "DnsRecord"
        unless entity.created_by?("whois")
          start_recursive_task(task_result,"whois",entity, [
              {"name" => "opt_create_contacts", "value" => false }])
        end
      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end

    end

end
end
end
