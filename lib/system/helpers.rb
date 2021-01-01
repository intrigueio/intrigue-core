module Intrigue
module Core
module System
  module Helpers

    def hostname
      system_name = `hostname`.strip
    end

    def entity_exists?(project, entity_type, entity_name)
      return false unless project
      entities = Intrigue::Core::Model::Entity.scope_by_project_and_type(project.name, entity_type)
      return entities.first(:name => entity_name) if entities
    false
    end

    ###
    ### Helper method for starting a task run
    ###
    def start_task(queue, project, existing_scan_result_id, task_name, entity, depth,
          options=[], handlers=[], machine_name="external_discovery_light_active", auto_enrich=true, auto_scope=false)
      
      # Create the task result, and associate our entity and options
      logger = Intrigue::Core::Model::Logger.create(:project_id => project.id)
      task_result = Intrigue::Core::Model::TaskResult.create({
        :project_id => project.id,
        :logger_id => logger.id,
        :name => "#{task_name}_on_#{entity.name}",
        :task_name => task_name,
        :options => options,
        :handlers => [],
        :base_entity => entity,
        :autoscheduled => (queue == "task_autoscheduled" || queue == "task_enrichment"),
        :auto_enrich => auto_enrich,
        :auto_scope => auto_scope,
        :depth => depth
      })

      # cancel any new tasks if the project has been cancelled
      if project.cancelled
        task_result.cancel!
      end

      # only assign handlers if this isn't a scan (in that case, we want to send the whole scan)
      task_result.handlers = handlers unless (!existing_scan_result_id && depth > 1)

      # if we were passed a scan result, we know this new task
      # belongs to it, and we should associate those
      if existing_scan_result_id

        # we are in the middle of a change, let's preserve the recursive trail
        task_result.scan_result_id = existing_scan_result_id
        task_result.save_changes

        # lets also add one to the incomplete task count, so we can determine if we're actually done
        #existing_scan_result.increment_task_count
      end

      # If the depth is greater than 1, AND we don't have a
      # prexisting scan id, start a new scan
      if !existing_scan_result_id && depth > 1
        logger = Intrigue::Core::Model::Logger.create(:project => project)
        new_scan_result = Intrigue::Core::Model::ScanResult.create({
          :name => "#{machine_name}_on_#{entity.name}",
          :project => project,
          :base_entity_id => entity.id,
          :logger_id => logger.id,
          :depth => depth,
          :machine => machine_name,
          :whitelist_strings => ["#{entity.name}"], # this is a list of strings that we know are good
          :blacklist_strings => [],
          :handlers => handlers,
          :incomplete_task_count => 0
        })

        # Add the scan result
        task_result.scan_result_id = new_scan_result.id
        task_result.save_changes

        # Add the task result
        new_scan_result.add_task_result(task_result)

        # Start it
        new_scan_result.start(queue)

      else

        # otherwise, we're a task, and we're ready to go
        task_result.start(queue)

      end

    task_result
    end

  end
end
end
end