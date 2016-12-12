class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    ###                  ###
    ### System Config    ###
    ###                  ###

    post '/:project/config/system' do
      global_config = Intrigue::Config::GlobalConfig.new
      global_config.config["credentials"]["username"] = "#{params["username"]}"
      global_config.config["credentials"]["password"] = "#{params["password"]}"
      global_config.save
      redirect "/v1/#{@project_name}"  # handy if we're in a browser
    end

    # save the config
    post '/:project/config/module' do
      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      global_config = Intrigue::Config::GlobalConfig.new
      params.each do |k,v|
        # skip unless we already know about this config setting, helps us avoid
        # other parameters sent to this page (splat, project, etc)
        next unless global_config.config["intrigue_global_module_config"][k]
        global_config.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/
      end
      global_config.save

      redirect "/v1/#{@project_name}"  # handy if we're in a browser
    end

    ###                ###
    ### Project Mgmt   ###
    ###                ###

    # Create a project!
    post '/project' do

      # When we create the project, we want to make sure no HTML is
      # stored, as we'll use this for display later on...
      new_project_name = CGI::escapeHTML(params[:project])

      # create the project unless it exists
      unless Intrigue::Model::Project.first(:name => new_project_name)
        Intrigue::Model::Project.create(:name => new_project_name)
      end

      redirect "/v1/#{new_project_name}/task" # handy if we're in a browser
    end

    # save the config
    post '/project/delete' do

      # we have to collect the name bc we skip the before block
      @project_name = params[:project]
      project = Intrigue::Model::Project.first(:name => @project_name)

      # create the project unless it exists
      if project
        project.destroy!

        # recreate the default project if we've removed
        if @project_name == "Default"
          Intrigue::Model::Project.create(:name => "Default")
        end
      end

      redirect '/v1/' # handy if we're in a browser
    end

    # Project Graph

    get '/:project/graph.json/?' do
      content_type 'application/json'
      project = Intrigue::Model::Project.first(:name => @project_name)
      project.export_graph_json
    end

    ###                                  ###
    ### System-Level Informational Calls ###
    ###                                  ###

    # Return a JSON array of all entity type
    get '/entity_types.json' do
      content_type 'application/json'
      Intrigue::Model::Entity.descendants.sort_by{|x| x.metadata[:name] }.map {|x| x.new.type_string }.to_json
    end

    # Export All Tasks
    get '/tasks.json/?' do
      content_type 'application/json'
      tasks = []
       Intrigue::TaskFactory.list.each do |t|
          tasks << t.metadata
      end
    tasks.to_json
    end

    # Export a single task
    get '/tasks/:task_name.json/?' do
      content_type 'application/json'
      task_name = params[:task_name]
      Intrigue::TaskFactory.list.select{|t| t.metadata[:name] == task_name}.first.metadata.to_json
    end

    ###                      ###
    ### Per-Project Entities ###
    ###                      ###

    get '/:project/entities/:id.csv' do
      content_type 'text/plain'
      @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      @entity.export_csv
    end

    get '/:project/entities/:id.json' do
      content_type 'application/json'
      @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      @entity.export_json
    end

    ###                          ###
    ### Per-Project Task Results ###
    ###                          ###

    # Create a task result from a json request
    # What we receive should look like this:
    #
    #payload = {
    #  "project_name" => project_name,
    #  "handlers" => []
    #  "task" => task_name,
    #  "entity" => entity_hash,
    #  "options" => options_list,
    #}.to_json
    post '/:project/task_results/?' do

      project_name = params[:project]

      # Parse the incoming request
      payload = JSON.parse(request.body.read) if request.content_type == "application/json"

      ### don't take any shit
      return nil unless payload

      # Construct an entity from the entity_hash provided
      type = payload["entity"]["type"]
      name = payload["entity"]["name"]

      # Collect the depth (which can kick off a recursive "scan", but default to a single)
      depth = payload["depth"] || 1

      type_class = eval("Intrigue::Entity::#{type}")

      attributes = payload["entity"].merge(
        "type" => type_class.to_s,
        "name" => "#{name}"
      )

      # get the details from the payload
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]

      # Try to find our project and create it if it doesn't exist
      project = Intrigue::Model::Project.first(:name => project_name)
      unless project
        project = Intrigue::Model::Project.create(:name => project_name)
      end

      # Try to find our entity
      # TODO: we should check all aliases here
      entity = Intrigue::Model::Entity.scope_by_project_and_type(project_name, type_class).first(:name => name)
      unless entity # If the entity didn't exist, create it
        entity = Intrigue::Model::Entity.create(attributes.merge(:project => project))
        entity.save
      end

      # Start the task_run
      task_result = start_task(project, task_name, entity, depth, options, handlers)
      status 200 if task_result

    # must be a string otherwise it can be interpreted as a status code
    task_result.id.to_s
    end

=begin
    # Accept the results of a task run
    post '/:project/task_results/:id/?' do
      raise "Broken?"
      # Retrieve the request's body and parse it as JSON
      result = JSON.parse(request.body.read)
      # Do something with event_json
      job_id = result["id"]
      # Return status
      status 200 if result
    end
=end

    # Export All task results
    get '/:project/task_results.json/?' do
       raise "Not implemented"
    end

    # Show the results in a CSV format
    get '/:project/task_results/:id.csv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @task_result.export_csv
    end

    # Show the results in a CSV format
    get '/:project/task_results/:id.tsv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/:project/task_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_json if @result
    end


    # Determine if the task run is complete
    get '/:project/task_results/:id/complete/?' do
      # Get the task result and return unless it's false
      x = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return false unless x

      # if we got it, and it's complete, return true
      return "true" if x.complete

    # Otherwise, not ready yet, return false
    false
    end

    # Get the task log
    get '/:project/task_results/:id/log/?' do
      content_type 'application/json'
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless @result

      {:data => @result.log}.to_json
    end

  end
end
