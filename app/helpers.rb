module Intrigue
  module Task
    module Helper

      ###
      ### Helper method for starting a task run
      ###
      def start_task_run(task_id, task_name, entity, options)

        # XXX - handle
        handlers=[]

        # Create the task result, and associate our entity and options
        task_result = Intrigue::Model::TaskResult.new task_id, task_name
        task_result.task_name = task_name
        task_result.options = options
        task_result.entity = entity ### XXX= Should this be an entity object?!?!

        # Save our task result so it can be picked up by our background processor
        task_result.save

        ###
        # Create the task
        ###
        task = Intrigue::TaskFactory.create_by_name(task_result.task_name)

        # note, this input is untrusted.
        jid = task.class.perform_async task_id, task_result.entity.id, task_result.options, handlers
      end

end
end
end
