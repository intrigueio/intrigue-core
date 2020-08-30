class CoreApp < Sinatra::Base

  # Read projects
  get "/api/v1/projects/?" do
    content_type 'application/json'
    
    halt_unless_authenticated!

    projects = Intrigue::Core::Model::Project.order(
      :created_at).reverse.all.map{|x| x.v1_api_hash(full=false) if x }.compact

  wrapped_api_response(nil, { projects: projects } )
  end

  # Create - DONE
  # Read - DONE 
  # Update
  # Delete - DONE

  # Create a project!
  post '/api/v1/project/?' do

    content_type "application/json"
    
    halt_unless_authenticated!

    # When we create the project, we want to make sure no HTML is
    # stored, as we'll use this for display later on...
    project_name = get_json_payload["name"]
    new_project_name = CGI::escapeHTML(project_name)
    
    # don't allow empty project names
    if new_project_name.length == 0
      out = wrap_core_api_response "Unable to create unnamed project: #{new_project_name}"
    end

    # create the project unless it exists
    if Intrigue::Core::Model::Project.first(:name => new_project_name)
      out = wrap_core_api_response "Project exists!"
    else
      Intrigue::Core::Model::Project.create(:name => new_project_name, :created_at => Time.now.utc)
    end

    unless out 
      # woo success
      out = wrap_core_api_response "Project created!", { project: "#{new_project_name}"} 
    end

  out 
  end

  # Read a specific project
  get "/api/v1/project/:project_name/?" do
    content_type 'application/json'
    
    halt_unless_authenticated!

    # get the project and return it
    project_name = @params[:project_name]
    project = Intrigue::Core::Model::Project.first(:name => "#{project_name}")

    unless project
      return wrapped_api_response("unable to locate project", nil )
    end

  wrapped_api_response(nil, { project: project.v1_api_hash(full=true) } )
  end

  patch "/api/v1/project/:project_name/?" do
    content_type 'application/json'
    
    halt_unless_authenticated!

    # get the project and return it
    project_name = @params[:project_name]
    project = Intrigue::Core::Model::Project.first(:name => "#{project_name}")

    unless project
      return wrapped_api_response("unable to locate project", nil )
    end

    config = get_json_payload || {}

    # set standard exceptions
    if config.has_key? "use_standard_exceptions"
      project.use_standard_exceptions = config["use_standard_exceptions"]
    end

    # set vulnerability_checks_enabled
    if config.has_key? "vulnerability_checks_enabled"
      project.vulnerability_checks_enabled = config["vulnerability_checks_enabled"]
    end

    # set reenrich
    if config.has_key? "allow_entity_reenrich"
      project.allow_reenrich = config["allow_entity_reenrich"]
    end

    # set allowed namespaces
    project.allowed_namespaces = config["allowed_namespaces"]
    
    # seeds 
    (config["seeds"]|| []).each do |s|
      
      # TODO... type checking goes here 
      # XXX - VERIFY THAT THIS IS A VALID TYPE

      entity_hash = {
        type: "#{s["type"]}",
        name: "#{s["name"]}",
        project_id: project.id,
        seed: true
      }

      puts "Entity hash: #{entity_hash}"

      Intrigue::Core::Model::Entity.update_or_create(entity_hash)
    end

    # save it!
    project.save

  wrapped_api_response(nil, { project: project.v1_api_hash(full=true) } )
  end





  # Read a specific project
  delete "/api/v1/project/:project_name/?" do
    content_type 'application/json'
    
    halt_unless_authenticated!

    # get the project and return it
    project_name = @params[:project_name]
    project = Intrigue::Core::Model::Project.first(:name => "#{project_name}")

    unless project
      return wrapped_api_response("unable to locate project", nil )
    end

    project.delete!

  wrapped_api_response(nil, nil)
  end


end