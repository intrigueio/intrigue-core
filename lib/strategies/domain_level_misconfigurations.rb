module Intrigue
module Strategy
  class DomainMisconfigurations < Intrigue::Strategy::Base

    def self.metadata
      {
        :name => "domain_misconfigurations",
        :pretty_name => "Check Domain Misconfigurations",
        :passive => true,
        :user_selectable => false,
        :authors => ["jcran"],
        :description => "This strategy checks for common misconfigurations in a TLD."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "DnsRecord"
        start_recursive_task(task_result,"public_google_groups_check",entity)
        start_recursive_task(task_result,"aws_s3_brute",entity)
        start_recursive_task(task_result,"public_trello_check",entity)
      end
    end

end
end
end
