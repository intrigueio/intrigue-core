module Intrigue
module Strategy
  class Base

    include Sidekiq::Worker
    sidekiq_options :queue => "task_scan", :backtrace => true

    include Intrigue::Task::Helper

    def self.inherited(base)
      StrategyFactory.register(base)
    end

    def perform(entity_id, task_result_id)
      task_result = Intrigue::Model::TaskResult.first(:id => task_result_id)
      entity = Intrigue::Model::Entity.first(:id => entity_id)

      # hold on recursion until we're enriched
      max_wait_iterations = 100
      until (entity.enriched || entity.enrichment_tasks.empty?)
        # make sure we re-lookup so we don't get stuck in loop
        entity = Intrigue::Model::Entity.first :id => entity.id

        # ... enrichment should be fast
        # don't get stuck in a loop forever (3 mins max)
        max_wait_iterations-=1
        if max_wait_iterations < 0
          old_task_result.log_fatal "Max enrichment wait exceeded for: #{entity.type} #{entity.name}"
          break
        end

        sleep 1
        #puts "Waiting on enrichment... #{entity.type} #{entity.name}: #{entity.enriched}"
      end

      # sanity check before sending us off
      return unless entity && task_result

      recurse(entity, task_result)
    end

    ###
    # Helper method for starting a task run
    ###
    def start_recursive_task(old_task_result, task_name, entity, options=[])
      project = old_task_result.project

      # check to see if it already exists, return nil if it does
      existing_task_result = Intrigue::Model::TaskResult.where(:project => project).first(:task_name => "#{task_name}", :base_entity_id => entity.id)

      if existing_task_result && (existing_task_result.options == options)
        # Don't schedule a new one, just notify that it's already scheduled.
        return nil
      else

        task_class = Intrigue::TaskFactory.create_by_name(task_name).class
        forced_queue = task_class.metadata[:queue]

        new_task_result = start_task(forced_queue || "task_autoscheduled", project,
                            old_task_result.scan_result,
                            task_name,
                            entity,
                            old_task_result.depth - 1,
                            options,
                            old_task_result.handlers,
                            old_task_result.scan_result.strategy,
                            old_task_result.auto_enrich)

      end

    new_task_result
    end

end
end
end
