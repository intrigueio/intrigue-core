module Intrigue
module Strategy
  class RogueDomainSearch < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "rogue_domain_search",
        :pretty_name => "Rogue Domain Search",
        :passive => true,
        :authors => ["jcran"],
        :description => "This strategy runs whois on every domain and allows you to identify rogues."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "DnsRecord"
        unless entity.created_by?("whois")
          start_recursive_task(task_result,"whois",entity, [
              {"name" => "create_contacts", "value" => false }])
        end
      else
        task_result.log "No actions for entity: #{entity.type}##{entity.name}"
        return
      end

    end

end
end
end
