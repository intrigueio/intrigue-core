module Intrigue
module Task
module Helper

  ###
  ### Helper method for starting a task run
  ###
  def start_task(project, task_name, entity, depth=1, options=[], handlers=[])

    # Create the task result, and associate our entity and options
    # strategy = default
    # depth = default
    task_result = Intrigue::Model::TaskResult.create({
      :project => project,
      :logger => Intrigue::Model::Logger.create(:project => project),
      :name => "#{task_name} on #{entity.name}",
      :task_name => task_name,
      :options => options,
      :base_entity => entity,
      :handlers => handlers,
      :depth => depth
    })

    if depth > 1
      puts "Depth: #{depth}, setting up a scan result"
      strategy = "default"

      scan_result = Intrigue::Model::ScanResult.create({
        :name => "scan to depth #{depth} using strategy #{strategy} on #{entity.name}",
        :project => project,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :base_entity => entity,
        :depth => depth,
        :strategy => strategy,
        :handlers => handlers
      })
      # Add the task result
      scan_result.task_results << task_result
      scan_result.save

      # Add the scan result
      task_result.scan_result = scan_result
      task_result.save

      puts "Task Results for #{scan_result.inspect}: #{scan_result.task_results.inspect}"

      # Start the scan, which kicks off the first task
      scan_result.start

      return scan_result
    else
      # Just kick off the first task!
      task_result.start
      return task_result
    end

  end

end
end
end
