module Intrigue
module Strategy
  class WhoisIntel < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "whois_intel",
        :pretty_name => "Whois Intel",
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
