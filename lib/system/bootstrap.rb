module Intrigue
module Core
module System
module Bootstrap

  def bootstrap_system(config)
    extend Intrigue::Core::System::Helpers

    return nil unless config && config["projects"]

    ###
    ### TODO ... handle system configuration here
    ###
    ### Set any system configuration

    ###
    ### TODO ... handle task configuration here
    ###
    ### Set any task configuration
    #if config["task_configuration"]
    #  config["task_configuration"].each do |k,v|
    #    Intrigue::Core::System::Config.set_task_config(k,v)
    #  end
    #end

    # XXX - Assumes we start at a clean system!!!!
    config["projects"].each do |p|

      project_name = p["name"]

      # always generate a workflow name
      generated_workflow_name = "#{p["workflow_name"]}_#{SecureRandom.hex(6)}"
      workflow_definition = p["workflow_definition"]

      # And add a new user workflow from the definition -
      # this allows us to easily modify the workflow on the platform
      Intrigue::Core::Model::Workflow.add_user_workflow({
        name: generated_workflow_name,
        definition: workflow_definition
      })

      Intrigue::NotifierFactory.default.each do |x|
        x.notify("#{project_name} collection starting with #{p["seeds"].count if p["seeds"]} seeds, using workflow: #{generated_workflow_name}!")
      end

      @task_result.log "Working on project: #{project_name}" if @task_result

      project = Intrigue::Core::Model::Project.find_or_create(:name => "#{project_name}")

      # Set exclusion setting
      task_name = p["task_name"] || "create_entity"
      options = p["task_options"] || []
      depth = p["depth"] || 5
      scan_handlers = p["scan_handlers"] || []
      auto_enrich = p["auto_enrich"] || true
      auto_scope = true

      project.options = p["project_options"] || []

      # vulnerability checks must be enabled at the project level
      if p["vulnerability_checks_enabled"]
        project.vulnerability_checks_enabled = true
      else
        project.vulnerability_checks_enabled = false
      end

      project.use_standard_exceptions = p["use_standard_exceptions"] || true

      project.allowed_namespaces = p["allowed_namespaces"]
      project.uuid = p["collection_run_uuid"]
      project.save

      # Add our exceptions
      puts "Adding exceptions to the database"
      if config["additional_exception_list"]
        _add_no_traverse_entities(project.id,
          config["additional_exception_list"].sort.to_a)
      end

      # parse up the seeds
      parsed_seeds = p["seeds"].map{|s| _parse_entity_hash s }

      # handle no-seed cases
      next unless parsed_seeds.count > 0

      # Create a queue to hold our list of seeds & enqueue
      work_q = Queue.new
      parsed_seeds.each do |s|
        work_q.push(s)
      end

      # Create a pool of worker threads to work on the queue
      max_threads = 1
      max_threads = 3 if parsed_seeds.count > 100
      max_threads = 10 if parsed_seeds.count > 500

      workers = (0...max_threads).map do
        Thread.new do
          _log "Starting thread"
          begin

            while entity = work_q.pop(true)
              next unless entity # handle nil entries

              # Create & scope the entity
              created_entity = Intrigue::EntityManager.create_first_entity(
                project_name, entity["type"], entity["details"]["name"], entity["details"], entity["sensitive_details"])

              # just in case we tried to create an invalid entity, skip
              next unless created_entity

              # Kick off the task (don't set handler on the task)
              task_result = start_task(nil, project, nil, task_name,
                created_entity, depth, options, scan_handlers, generated_workflow_name, auto_enrich, auto_scope)

              # Manually start enrichment for the first entity
              created_entity.enrich(task_result) if auto_enrich
            end

          rescue ThreadError
          end
        end
      end; "ok"
      workers.map(&:join); "ok"

    end
  end




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
      "details" => { "name" => entity_name, "whitelist" => true },
      "sensitive_details" => {}
    }

  entity_hash
  end

  def _parse_entity_hash(entity_hash)
    if entity_hash.class != Hash
      puts "Error while parsing entity hash: Invalid type"
      return nil
    end

    parsed_entity_hash = Intrigue::Core::System::Bootstrap::_parse_entity(entity_hash["entity"]) # have to namespace for core-cli to work

    # merge details from bootstrap seed entity
    if entity_hash.key?("details")
      parsed_entity_hash["details"] = parsed_entity_hash["details"].merge(entity_hash["details"])
    end

    if entity_hash.key?("sensitive_details")
      parsed_entity_hash["sensitive_details"] = parsed_entity_hash["sensitive_details"].merge(entity_hash["sensitive_details"])
    end

  parsed_entity_hash
  end

  private
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
end
end