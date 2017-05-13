module Intrigue
module Task
module Helper

  def entity_exists?(project, entity_type, entity_name)
    puts "Checking for existence of an entity with type: #{entity_type} and name: #{entity_name} in project: #{project.name}"

    Intrigue::Model::Entity.scope_by_project_and_type(project.name, entity_type).each do |e|
      if e.unique_name.include? entity_name
        puts "Found! #{entity_name} in #{e.unique_name}"
        return e
      end
    end

  puts "Not Found! #{entity_name}"
  false
  end

  ###
  ### Helper method for starting a task run
  ###
  def start_task(queue, project, existing_scan_result, task_name, entity, depth, options=[], handlers=[], strategy_name="discovery")

    # Create the task result, and associate our entity and options
    task_result = Intrigue::Model::TaskResult.create({
      :project => project,
      :logger => Intrigue::Model::Logger.create(:project => project),
      :name => "#{task_name} on #{entity.name}",
      :task_name => task_name,
      :options => options,
      :handlers => [],
      :base_entity => entity,
      :autoscheduled => (queue == "task_autoscheduled" || queue == "task_enrichment"),
      :depth => depth
    })

    # only assign handlers if this isn't a scan (in that case, we want to send the whole scan)
    task_result.handlers = handlers unless (!existing_scan_result && depth > 1)

    # if we were passed a scan result, we know this new task
    # belongs to it, and we should associate those
    if existing_scan_result
      task_result.scan_result_id = existing_scan_result.id
      # lets also add one to the incomplete task count, so we can determine later
      # if we're actually done
      task_result.scan_result.incomplete_task_count += 1
      task_result.save
    end

    # If the depth is greater than 1, AND we don't have a
    # prexisting scan id, start a new scan
    if !existing_scan_result && depth > 1

      scan_result = Intrigue::Model::ScanResult.create({
        :name => "#{strategy_name} to depth #{depth} on #{entity.name}",
        :project => project,
        :base_entity_id => entity.id,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :depth => depth,
        :strategy => strategy_name,
        :handlers => handlers,
        :incomplete_task_count => 1
      })

      # Add the task result
      scan_result.add_task_result(task_result) && scan_result.save

      # Add the scan result
      task_result.scan_result = scan_result && task_result.save

      # Start it
      scan_result.start(queue)

    else
      # otherwise, we're a task, and we're ready to go
      task_result.start(queue)
    end

  task_result
  end

end
end
end
