module Intrigue
  module Task
    module Helper

      ###
      ### Helper method for starting a task run
      ###
      def start_task_run(task_id, task_name, entity, options)

        # Create the task result, and associate our entity and options
        task_result = Intrigue::Model::TaskResult.new task_id, "x"
        task_result.task_name = task_name
        task_result.options = options
        task_result.entity = entity

        # Save our task result so it can be picked up by our background processor
        task_result.save

        ###
        # Create the task
        ###
        task = Intrigue::TaskFactory.create_by_name(task_result.task_name)

        # note, this input is untrusted.
        jid = task.class.perform_async task_id, task_result.entity.id, task_result.options, ["webhook"], "http://127.0.0.1:7777/v1/task_results/#{task_id}"
      end

end
end
end
