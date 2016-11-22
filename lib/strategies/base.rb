module Intrigue
module Strategy
  class Base

    def self.inherited(base)
      StrategyFactory.register(base)
    end

    ###
    ### Helper method for starting a task run
    ###
    def self.start_recursive_task(old_task_result, task_name, entity, options=[], handlers=[])
      puts "Starting recursive task #{task_name}"

      project = old_task_result.project

      # Create the task result, and associate our entity and options
      new_task_result = Intrigue::Model::TaskResult.create({
          :name => "#{task_name}",
          :task_name => task_name,
          :options => options,
          :base_entity => entity,
          :logger => Intrigue::Model::Logger.create(:project => project),
          :project => project,
          :handlers => handlers,
          :strategy => "default",
          :depth => old_task_result.depth - 1
      })

      new_task_result.start

    new_task_result
    end

end
end
end
