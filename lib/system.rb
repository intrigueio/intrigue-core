module Intrigue
module System

  def bootstrap_system(config)
    extend Intrigue::Task::Helper

    # XXX - Assumes we start at a clean system!!!!
    config["projects"].each do |p|
      project_name = p["name"]

      project = Intrigue::Model::Project.find_or_create(:name => "#{project_name}")

      # Set exclusion setting
      auto_enrich = p["auto_enrich"] || true
      project.use_standard_exceptions = p["use_standard_exceptions"]
      project.additional_exception_list = config["additional_exception_list"]
      project.save

      @task_result.log "Working on project: #{project_name}" if @task_result
      p["seeds"].each do |s|
        @task_result.log " - Seed: #{s}" if @task_result

        entity = _parse_entity s["entity"]
        task_name = s["task"] || "create_entity"
        machine = s["machine"] || "org_asset_discovery_active"
        depth = s["depth"] || 5
        options = s["options"] || []
        handlers = s["handlers"] || []

        # Create the entity
        created_entity = Intrigue::EntityManager.create_first_entity(project_name, entity["type"], entity["details"]["name"], entity["details"])

        # Kick off the task
        task_result = start_task(nil, project, nil, task_name, created_entity, depth, options, handlers, machine, auto_enrich)

        # Manually start enrichment for the first entity
        created_entity.enrich(task_result) if auto_enrich

      end

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
