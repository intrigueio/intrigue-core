module Intrigue
module Machine
  class EveryDiscoveryTask < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "every_discovery_task",
        :pretty_name => "Run Every Discovery Task",
        :passive => false,
        :user_selectable => false,
        :authors => ["jcran","AnasBenSalah"],
        :description => "This machine runs all tasks for a given entity."
      }
    end

    def self.recurse(entity, task_result)

      # enumerate what we'll run on
      allowed_entity_types = ["Domain", "DnsRecord", "IpAddress"]
      unless allowed_entity_types.include? entity.type_string
        task_result.log "Can't do anything with this entity type, returning: #{entity.type_string}"
        return
      end

      # get the names that apply for us to run
      task_names = get_runnable_tasks_for_type entity.type_string
      task_result.log "Running: #{task_names}"

      # run'm
      task_names.each do |tn|
        start_recursive_task(task_result, tn, entity)
      end

    end


    def self.get_runnable_tasks_for_type(entity_type)

      tasks = Intrigue::TaskFactory.allowed_tasks_for_entity_type entity_type
      result = tasks.sort_by{|x| x.metadata[:name] }.map do |task|

        # return the appropriate thing
        next if task.metadata[:type] == "creation"
        next if task.metadata[:type] == "vuln_check"
        next if task.metadata[:type] == "enrichment"
        next if task.metadata[:type] == "example"

        task.metadata[:name]
      end

    result.uniq.compact
    end


end
end
end
