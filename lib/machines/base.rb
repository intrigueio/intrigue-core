module Intrigue
module Machine
  class Base

    extend Intrigue::Core::System::Helpers
    extend Intrigue::Task::Data

    def self.inherited(base)
      MachineFactory.register(base)
    end

    def self.start(entity, task_result)

      # sanity check before sending us off
      return unless entity && task_result

      recurse(entity, task_result)
    end

    ###
    # Helper method for starting a task run
    ###
    def self.start_recursive_task(old_task_result, task_name, entity, options=[], auto_scope=false)
      project = old_task_result.project

      # check to see if it already exists, return nil if it does
      existing_task_result = Intrigue::Core::Model::TaskResult.first(
        :project => project,
        :task_name => "#{task_name}",
        :base_entity_id => entity.id
      )

      if existing_task_result && (existing_task_result.options == options)
        # Don't schedule a new one, just notify that it's already scheduled.
        return nil
      else

        task_class = Intrigue::TaskFactory.create_by_name(task_name).class
        forced_queue = task_class.metadata[:queue]

        new_task_result = start_task(forced_queue || "task_autoscheduled", 
                            project,
                            old_task_result.scan_result.id,
                            task_name,
                            entity,
                            old_task_result.depth - 1,
                            options,
                            old_task_result.handlers,
                            old_task_result.scan_result.machine,
                            old_task_result.auto_enrich,
                            auto_scope)

      end

    new_task_result
    end

end
end
end
