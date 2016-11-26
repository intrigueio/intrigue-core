module Intrigue
module Task
module Helper

  ###
  ### Helper method for starting a task run
  ###
  def start_task(project, task_name, entity, options=[], handlers=[])

    # Create the task result, and associate our entity and options
    # strategy = default
    # depth = default
    task_result = Intrigue::Model::TaskResult.create({
        :name => "#{task_name} on #{entity.name}",
        :task_name => task_name,
        :options => options,
        :base_entity => entity,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :project => project,
        :handlers => handlers,
        :strategy => "default"
    })

    task_result.start

  task_result
  end

end
end
end
