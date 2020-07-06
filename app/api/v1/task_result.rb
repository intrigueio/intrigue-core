class CoreApp < Sinatra::Base

  # Create a task result!
  post '/api/v1/task_result' do
    content_type "application/json"
    
    halt_unless_authenticated(@params["key"])

    # When we create the project, we want to make sure no HTML is
    # stored, as we'll use this for display later on...
    payload = get_json_payload
    
    project_name = payload[:project_name]
    task_name = payload[:task_name]
    entity_type_string = payload[:entity_type_string]
    entity_name = payload[:entity_name]
    
    # fail unless we have these 
    unless project_name && task_name && entity_type_string && entity_name
      return wrap_core_api_response "Unable to create task result, missing required parameter"
    end

    # optional / defaulted parameters
    entity_details = payload[:entity_details] || {}
    task_options = payload[:task_options] || {}
    
    handler_names = "#{payload[:handler_names]}".split(",") || []
    
    machine_name = payload[:machine_name] || nil
    machine_depth = payload[:machine_depth] || 1

    auto_enrich = payload[:auto_enrich] || true
    auto_scope = payload[:auto_scope] || false
    queue_name = payload[:queue_name] || "task"

    # determine our type from the type string
    project_object = Intrigue::Core::Model::Project.first :name => project_name
    unless project_object
      return wrap_core_api_response "Invalid project"
    end      


    # determine our type from the type string
    resolved_type = Intrigue::EntityManager.resolve_type_from_string entity_type_string
    unless resolved_type
      return wrap_core_api_response "Invalid type"
    end      

    # create the entity
    entity_object = Intrigue::EntityManager.create_first_entity(project_name, entity_type_string, entity_name, entity_details)
    unless entity_object
      return wrap_core_api_response "Unable to create entity"
    end      

    # Start the task_run
    scan_result_id = nil # only applicable if we're called from a machine
    task_result = start_task(queue_name, project_object, scan_result_id, task_name, entity_object, machine_depth,
                                task_options, handler_names, machine_name, auto_enrich, auto_scope)

    # manually start enrichment, since we've already created the entity above, it won't auto-enrich ^
    if auto_enrich && !(task_name =~ /^enrich/)
      task_result.log "User-created entity, manually creating and enriching!"
      entity_object.enrich(task_result)
    end

    # woo success
    wrap_core_api_response "Task result created!", { task_result_id: task_result.id } 
  end

end