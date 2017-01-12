  module Intrigue
module Task
module Helper

  ###
  ### Helper method for starting a task run
  ###
  def start_task(queue, project, existing_scan_result, task_name, entity, depth=1, options=[], handlers=[])

    # Create the task result, and associate our entity and options
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

    # if we were passed a scan result, we know this new task belongs to it, and we should associate those
    if existing_scan_result
      task_result.scan_result_id = existing_scan_result.id
      task_result.save
    end

    # If the depth is greater than 1, AND we don't have a prexisting scan id, start a new scan
    if !existing_scan_result && depth > 1

      strategy = "default"
      scan_result = Intrigue::Model::ScanResult.create({
        :name => "scan to depth #{depth} using strategy #{strategy} on #{entity.name}",
        :project => project,
        :base_entity_id => entity.id,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :depth => depth,
        :strategy => strategy,
        :handlers => handlers
      })

      # Add the task result
      scan_result.add_task_result task_result
      scan_result.save

      # Add the scan result
      task_result.scan_result = scan_result
      task_result.save

      puts "Task Results for #{scan_result.name}: #{scan_result.task_results.count}"
      _schedule_task(queue, scan_result.task_results.first)

    else
      # If it's not a new scan, just kick off the task result
      _schedule_task(queue, task_result)
    end

  task_result
  end

  # handle running of tasks
  private
  def _schedule_task(queue, task_result)

    if queue == "task_autoscheduled"
      task_result.autoscheduled = true
      task_result.save

      Sidekiq::Client.push({
        "class" => Intrigue::TaskFactory.create_by_name(task_result.task_name).class.to_s,
        "queue" => "task_autoscheduled",
        "retry" => true,
        "args" => [task_result.id, task_result.handlers]
      })
    else # task queue
      task_result.start
    end
  end

end
end
end
