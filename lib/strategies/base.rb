module Intrigue
module Strategy
  class Base

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

      # Create the task result, and associate our entity and options
      new_task_result = Intrigue::Model::TaskResult.create({
          :scan_result => old_task_result.scan_result,
          :name => "#{task_name} on #{entity.name}",
          :task_name => task_name,
          :options => options,
          :base_entity => entity,
          :logger => Intrigue::Model::Logger.create(:project => project),
          :project => project,
          :handlers => old_task_result.handlers,
          :depth => old_task_result.depth - 1
      })

      # start this in a lower priority queue
      # yes this is ugly.
      # http://coderascal.com/ruby/using-sidekiq-across-different-applications/
      # http://tech.tulentsev.com/2012/12/queue-prioritization-in-sidekiq/
      # http://stackoverflow.com/questions/20080047/how-to-push-job-in-specific-queue-and-limit-number-workers-with-sidekiq
      #
      #require 'sidekiq'
      Sidekiq::Client.push({
        "class" => Intrigue::TaskFactory.create_by_name(task_name).class.to_s,
        "queue" => "task_recursive",
        "retry" => true,
        "args" => [new_task_result.id, new_task_result.handlers]
      })

      #{ 'class' => SomeWorker, 'args' => ['bob', 1, :foo => 'bar'] }
    new_task_result
    end

end
end
end
