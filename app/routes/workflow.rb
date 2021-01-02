class CoreApp < Sinatra::Base

  post '/:project_name/workflow/?' do

    # then set up the initial task results 
    depth = (@params["depth"] || 6).to_i
    workflow = "#{@params["workflow"]}"

    ###
    ### Standard file type (entity list)
    ###
    entities = "#{@params["entitylist"]}".split("\n").map do |x| 
      { entity_name: "#{x}".strip.downcase }
    end

    ### Machine definition, make sure we have a valid type
    if Intrigue::MachineFactory.has_machine? workflow
      machine_name = workflow
    else 
      session[:flash] = "Invalid workflow!"
      redirect FRONT_PAGE
    end

    # set our project (default)
    current_project = Intrigue::Core::Model::Project.first(:name => @project_name)

    # for each entity in the list
    entities.each do |e|
      
      entity_name = e[:entity_name]
      entity_type = discern_entity_types_from_name(entity_name).first

      # create the first entity with empty details
      #next unless Intrigue::EntityFactory.entity_types.include?(entity_type)
      entity = Intrigue::EntityManager.create_first_entity(@project_name, entity_type ,entity_name, {})

      # skip anything we can't parse, silently fail today :[
      unless entity
        next
      end

      task_name = "create_entity"
      handlers = []
      depth = depth
      auto_enrich = true 
      auto_scope = true  

      # Start the task run!
      task_result = start_task("task", current_project, nil, task_name, entity,
                depth, nil, handlers, machine_name, auto_enrich, auto_scope)

      entity.task_results << task_result
      entity.save

      # manually start enrichment for the first entity
      if auto_enrich && !(task_name =~ /^enrich/)
        task_result.log "User-created entity, manually creating and enriching!"
        entity.enrich(task_result)
      end

    end

    redirect "/#{@project_name}/results"
  end

end