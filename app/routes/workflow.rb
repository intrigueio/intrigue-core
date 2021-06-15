class CoreApp < Sinatra::Base

  post '/:project_name/workflow/?' do

    # then set up the initial task results
    workflow_name = "#{@params["workflow"]}"

    ###
    ### Standard file type (entity list)
    ###
    entities = "#{@params["entitylist"]}".split("\n").map do |x|
      "#{x}".strip.downcase
    end

    ### Workflow definition, make sure we have a valid type
    if wf = Intrigue::WorkflowFactory.create_workflow_by_name(workflow_name)
      workflow_name = wf.name
      workflow_depth = wf.depth
    else
      session[:flash] = "Invalid workflow!"
      redirect FRONT_PAGE
    end

    # set our project (default)
    current_project = Intrigue::Core::Model::Project.first(:name => @project_name)

    # for each entity in the list
    entities.each do |e|

      entity_name = e
      entity_type = discern_entity_types_from_name(entity_name).first

      # create the first entity with empty details
      #next unless Intrigue::EntityFactory.entity_types.include?(entity_type)
      entity = Intrigue::EntityManager.create_first_entity(
        @project_name, entity_type, entity_name, {})

      # skip anything we can't parse, silently fail today :[
      unless entity
        next
      end

      task_name = "create_entity"
      handlers = []
      auto_enrich = true
      auto_scope = true

      # Start the task run!
      task_result = start_task("task", current_project, nil, task_name, entity,
        workflow_depth, nil, handlers, workflow_name, auto_enrich, auto_scope)

      entity.task_results << task_result
      entity.save

      # manually start enrichment for the first entity
      #if auto_enrich && !(task_name =~ /^enrich/)
      #  task_result.log "User-created entity, manually creating and enriching!"
      #  entity.enrich(task_result)
      #end

    end

    redirect "/#{@project_name}/results"
  end

end