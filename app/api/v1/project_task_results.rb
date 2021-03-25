class CoreApp < Sinatra::Base

  # Create - DONE
  # Read - DONE
  # Update -
  # Delete -

  #{
  #  :project_name => "Default", # string, any valie project name, see /api/v1/projects
  #  :task_name => "example", # string, see /api/v1/tasks api for a list of possible values
  #  :entity_type_string => "Domain", # string, see /api/v1/entities api for a list of possible values
  #  :entity_name => "test.com" # string, the name of this entity
  #  :entity_details => {}, # hash of values, usually empty
  #  :task_options => [{name: "value1", name2: "value2"}],  # hash of values # TODO... verify this format
  #  :handler_names => [], # list of strings, see /api/v1/handlers for a list of possible values
  #  :workflow_name => "profile_organization_external_light_active", # string, a valid workflow name, see /api/v1/workflows for a list of valid values
  #  :workflow_name => 1, # integer, max depth (can be 1-5)
  #  :auto_enrich => 1, # bool, specifies whether to run the automatic entity enrichment
  #  :auto_scope => 1, # bool, specifies whether to automatically scope this entity in
  #  :queue_name => "task", # string specifying which queue to place the task in. best left as 'task'
  #}

  # Create a task result!
  post '/api/v1/:project/task_result/?' do
    content_type "application/json"

    halt_unless_authenticated!

    # When we create the project, we want to make sure no HTML is
    # stored, as we'll use this for display later on...
    payload = get_json_payload

    project_name = payload["project_name"]
    task_name = payload["task_name"]
    entity_type_string = payload["entity_type_string"]
    entity_name = payload["entity_name"]

    # fail unless we have these
    unless project_name && task_name && entity_type_string && entity_name
      return wrapped_api_response "Unable to create task result, missing required parameter"
    end

    # optional / defaulted parameters
    entity_details = payload["entity_details"] || {}
    task_options = payload["task_options"] || {}

    handler_names = payload["handler_names"] || []

    workflow_name = payload["workflow_name"] || nil
    workflow_depth = payload["workflow_depth"] || 1

    auto_enrich = payload["auto_enrich"] || true
    auto_scope = payload["auto_scope"] || false
    queue_name = payload["queue_name"] || "task"

    # determine our type from the type string
    project_object = Intrigue::Core::Model::Project.first :name => project_name
    unless project_object
      return wrapped_api_response "Invalid project"
    end

    # determine our type from the type string
    resolved_type = Intrigue::EntityManager.resolve_type_from_string entity_type_string
    unless resolved_type
      return wrapped_api_response "Invalid type"
    end

    # create the entity
    entity_object = Intrigue::EntityManager.create_first_entity(project_name, entity_type_string, entity_name, entity_details)
    unless entity_object
      return wrapped_api_response "Unable to create entity"
    end

    # Start the task_run
    scan_result_id = nil # only applicable if we're called from a workflow
    task_result = start_task(queue_name, project_object, scan_result_id, task_name, entity_object, workflow_depth, task_options, handler_names, workflow_name, auto_enrich, auto_scope)

    # manually start enrichment, since we've already created the entity above, it won't auto-enrich
    if auto_enrich && !(task_name =~ /^enrich/)
      task_result.log "User-created entity, manually creating and enriching!"
      entity_object.enrich(task_result)
    end

    # woo success
    wrapped_api_response nil, { task_result_id: task_result.id }
  end

end