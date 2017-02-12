  module Intrigue
module Task
module Helper

  ###
  ### Helper method for starting a task run
  ###
  def start_task(queue, project, existing_scan_result, task_name, entity, depth, options=[], handlers=[])

    # Create the task result, and associate our entity and options
    task_result = Intrigue::Model::TaskResult.create({
      :project => project,
      :logger => Intrigue::Model::Logger.create(:project => project),
      :name => "#{task_name} on #{entity.name}",
      :task_name => task_name,
      :options => options,
      :handlers => [],
      :base_entity => entity,
      :autoscheduled => (queue == "task_autoscheduled"),
      :depth => depth
    })

    # if we were passed a scan result, we know this new task belongs to it, and we should associate those
    if existing_scan_result
      task_result.scan_result_id = existing_scan_result.id
      task_result.save
    end

    # If the depth is greater than 1, AND we don't have a prexisting scan id, start a new scan
    if !existing_scan_result && depth > 1

      strategy_name = "discovery"
      scan_result = Intrigue::Model::ScanResult.create({
        :name => "#{strategy_name} to depth #{depth} on #{entity.name}",
        :project => project,
        :base_entity_id => entity.id,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :depth => depth,
        :strategy => strategy_name,
        :handlers => handlers
      })

      # Add the task result
      scan_result.add_task_result(task_result) && scan_result.save

      # Add the scan result
      task_result.scan_result = scan_result && task_result.save

      # Start it
      scan_result.start(queue)

    else
      # Start it
      task_result.start(queue)
    end

  task_result
  end

end
end
end
