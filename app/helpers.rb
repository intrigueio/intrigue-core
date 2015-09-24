module Intrigue
  module Task
    module Helper

      ###
      ### Helper method for starting a task run
      ###
      def start_task_run(task_id, task_name, entity, options)

        # XXX - TODO - add the ability to specify handlers. expose this to the user
        handlers=[]

        # Create the task result, and associate our entity and options
        task_result = Intrigue::Model::TaskResult.new task_id, task_name
        task_result.task_name = task_name
        task_result.options = options
        task_result.entity = entity
        task_result.save

        ###
        # Create the task and start it
        ###
        task = Intrigue::TaskFactory.create_by_name(task_result.task_name)
        jid = task.class.perform_async task_id, task_result.entity.id, task_result.options, handlers
      end

end
end
end
