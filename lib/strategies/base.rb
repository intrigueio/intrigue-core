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

      # check to see if it already exists
      existing_task_result = Intrigue::Model::TaskResult.all(:project => project).first(:name => "#{task_name} on #{entity.name}")

      if existing_task_result
        #puts "Skipping!!!! Task result (#{task_name} on #{entity.name}) already exists."
        return existing_task_result
      else
        #puts "Starting recursive task: #{task_name} on #{entity.name}"
      end

      new_task_result = start_task("task_autoscheduled", project, old_task_result.scan_result, task_name, entity, old_task_result.depth - 1, options, old_task_result.handlers)

    new_task_result
    end

end
end
end
