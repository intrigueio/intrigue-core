module Intrigue
module Task
module Helper

  def entity_exists?(project, entity_type, entity_name)
    Intrigue::Model::Entity.scope_by_project_and_type(project.name, entity_type).first(:name => entity_name)
  end

  ###
  ### Helper method for starting a task run
  ###
  def start_task(queue, project, existing_scan_result, task_name, entity, depth,
                  options=[], handlers=[], machine_name="asset_discovery_active", auto_enrich=true, auto_scope=false)

    # Create the task result, and associate our entity and options
    task_result = Intrigue::Model::TaskResult.create({
      :project => project,
      :logger => Intrigue::Model::Logger.create(:project => project),
      :name => "#{task_name}_on_#{entity.name}",
      :task_name => task_name,
      :task_type => Intrigue::TaskFactory.create_by_name(task_name).class.metadata[:type],
      :options => options,
      :handlers => [],
      :base_entity => entity,
      :autoscheduled => (queue == "task_autoscheduled" || queue == "task_enrichment"),
      :auto_enrich => auto_enrich,
      :auto_scope => auto_scope,
      :depth => depth
    })

    # only assign handlers if this isn't a scan (in that case, we want to send the whole scan)
    task_result.handlers = handlers unless (!existing_scan_result && depth > 1)

    # if we were passed a scan result, we know this new task
    # belongs to it, and we should associate those
    if existing_scan_result

      # we are in the middle of recursion, let's preserve the chain
      task_result.scan_result_id = existing_scan_result.id
      task_result.save

      # lets also add one to the incomplete task count, so we can determine if we're actually done
      existing_scan_result.increment_task_count
    end

    # If the depth is greater than 1, AND we don't have a
    # prexisting scan id, start a new scan
    if !existing_scan_result && depth > 1

      scan_result = Intrigue::Model::ScanResult.create({
        :name => "#{machine_name}_on_#{entity.name}",
        :project => project,
        :base_entity_id => entity.id,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :depth => depth,
        :machine => machine_name,
        :whitelist_strings => ["#{entity.name}"], # this is a list of strings that we know are good
        :blacklist_strings => [],
        :handlers => handlers,
        :incomplete_task_count => 0
      })

      # Add the task result
      scan_result.add_task_result(task_result)
      scan_result.save

      # Add the scan result
      task_result.scan_result = scan_result
      task_result.save

      # update our count
      scan_result.increment_task_count

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
