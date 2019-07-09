module Intrigue
module System

  def bootstrap_system(config)
    extend Intrigue::Task::Helper

    return nil unless config["projects"]

    # XXX - Assumes we start at a clean system!!!!
    config["projects"].each do |p|

      Intrigue::NotifierFactory.default.each { |x| 
        x.notify("#{p["name"]} collection starting with #{p["seeds"].count if p["seeds"]} seeds!") }

      project_name = p["name"]
      @task_result.log "Working on project: #{project_name}" if @task_result

      project = Intrigue::Model::Project.find_or_create(:name => "#{project_name}")

      # Set exclusion setting

      task_name = p["task_name"] || "create_entity"
      options = p["task_options"] || []
      machine = p["machine"] || "org_asset_discovery_active"
      depth = p["depth"] || 5
      scan_handlers = p["scan_handlers"] || []
      auto_enrich = p["auto_enrich"] || true
      auto_scope = true

      project.options = p["project_options"] || []
      project.use_standard_exceptions = p["use_standard_exceptions"] || true

      if config["additional_exception_list"]
        project.additional_exception_list = config["additional_exception_list"].to_a
      else
        project.additional_exception_list = []
      end

      # parse up the seeds
      parsed_seeds = p["seeds"].map{|s| _parse_entity s["entity"] }
      project.seeds = parsed_seeds
      project.save

      # Create a queue to hold our list of seeds & enqueue
      work_q = Queue.new
      parsed_seeds.each do |s|
        work_q.push(s)
      end

      # Create a pool of worker threads to work on the queue
      max_threads = 20
      max_threads = 50 if parsed_seeds.count > 50
       workers = (0...max_threads).map do
        Thread.new do
          _log "Starting thread"
          begin

            while entity = work_q.pop(true)
              next unless entity # handle nil entries
              @task_result.log "Working on seed: #{entity}" if @task_result

              # Create & scope the entity
              created_entity = Intrigue::EntityManager.create_first_entity(
                project_name, entity["type"], entity["details"]["name"], entity["details"])

              # just in case we tried to create an invalid entity, skip
              next unless created_entity

              # Kick off the task (don't set handler on the task)
              task_result = start_task(nil, project, nil, task_name,
                created_entity, depth, options, scan_handlers, machine, auto_enrich, auto_scope)

              # Manually start enrichment for the first entity
              created_entity.enrich(task_result) if auto_enrich
            end

          rescue ThreadError
          end
        end
      end; "ok"
      workers.map(&:join); "ok"

      # sometimes we need to run a custom command in the context of a project
      if p["custom_commands"]
        p["custom_commands"].each do |c|
          Dir.chdir($intrigue_basedir) do
            `#{c["command"]}`
          end
        end
      end

    end
  end


  private

  # parse out entity from the cli
  def _parse_entity(entity_string)
    entity_type = entity_string.split("#").first

    # hack - fixes entities with full type
    unless entity_type =~ /::/
      entity_type = "Intrigue::Entity::#{entity_type}"
    end

    entity_name = entity_string.split("#").last

    entity_hash = {
      "type" => entity_type,
      "name" => entity_name,
      "details" => { "name" => entity_name, "whitelist" => true }
    }

    #puts "Got entity: #{entity_hash}" if @debug

  entity_hash
  end

  # Parse out options from cli
  def _parse_options(option_string)

      return [] unless option_string

      options_list = []
      options_list = option_string.split("#").map do |option|
        { "name" => option.split("=").first, "value" => option.split("=").last }
      end

  options_list
  end

  # Parse out options from cli
  def _parse_handlers(handler_string)
      return [] unless handler_string

      handler_list = []
      handler_list = handler_string.split(",")

  handler_list
  end

end
end
