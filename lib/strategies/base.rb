module Intrigue
module Strategy
  class Base

    extend Intrigue::Task::Helper

    def self.inherited(base)
      StrategyFactory.register(base)
    end

    ###
    ### Helper method for starting a task run
    ###
    def self.start_recursive_task(old_task_result, task_name, entity, options=[])
      project = old_task_result.project

      # check to see if it already exists, return nil if it does
      existing_task_result = Intrigue::Model::TaskResult.where(:project => project).first(:task_name => "#{task_name}", :base_entity_id => entity.id)

      if existing_task_result && (existing_task_result.options == options)
        # Don't schedule a new one, just notify that it's already scheduled.
        #old_task_result.logger.log "Existing run of #{task_name} on #{entity} with options #{options} already scheduled at depth #{existing_task_result.depth}. See: #{existing_task_result.id}."
        return nil
      else
        new_task_result = start_task("task_autoscheduled", project,
                            old_task_result.scan_result,
                            task_name,
                            entity,
                            old_task_result.depth - 1,
                            options,
                            old_task_result.handlers,
                            old_task_result.scan_result.strategy,
                            old_task_result.auto_enrich)

        #new_task_result.logger.log "Verified no other scheduled tasks exist: #{task_name} on #{entity} with options: #{options}"
        #new_task_result.logger.log "Starting: #{task_name} on #{entity} at depth #{old_task_result.depth}"
      end

    new_task_result
    end

end
end
end
