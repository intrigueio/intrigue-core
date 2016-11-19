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

      redirect "/v1/#{new_project_name}/scan" # handy if we're in a browser
    end

    # save the config
    post '/:project/delete' do
      project = Intrigue::Model::Project.first(:name => @project_name)

      # create the project unless it exists
      if project
        project.destroy!

        # recreate the default project if we've removed
        if @project_name == "Default"
          Intrigue::Model::Project.create(:name => "Default")
        end

        # move us to the default project if we removed our current_project
        #if @project_name == session["project_name"]
        #  session["project_name"] = "Default"
        #  response.set_cookie "project_name", :value => "Default"
        #end

      end

      redirect '/v1/' # handy if we're in a browser
    end

    ###                                  ###
    ### System-Level Informational Calls ###
    ###                                  ###

    # Return a JSON array of all entity type
    get '/entity_types.json' do
      content_type 'application/json'
      Intrigue::Model::Entity.descendants.map {|x| x.new.type_string }.to_json
    end

    # Export All Scan Type Info
    get '/scans.json/?' do
      content_type 'application/json'
      scans = []
       Intrigue::ScanFactory.list.each do |s|
          scans << s.send(:new).metadata
      end
    scans.to_json
    end

    # Export All Tasks
    get '/tasks.json/?' do
      content_type 'application/json'
      tasks = []
       Intrigue::TaskFactory.list.each do |t|
          tasks << t.send(:new).metadata
      end
    tasks.to_json
    end

    # Export a single task
    get '/tasks/:task_name.json/?' do
      content_type 'application/json'
      task_name = params[:task_name]
      Intrigue::TaskFactory.create_by_name(task_name).metadata.to_json
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
      attributes = payload["entity"].merge("type" => "Intrigue::Entity::#{type}")

      # get the details from the payload
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]

      # Try to find our project
      project = Intrigue::Model::Project.first(:name => project_name)
      unless project # If the project didn't exist, create it
        project = Intrigue::Model::Project.create(:name => project_name)
      end

      # Try to find our entity
      entity = Intrigue::Model::Entity.scope_by_project(project_name).first(
        :name => payload["entity"]["name"],
        :type => payload["entity"]["type"]
      )
      unless entity # If the entity didn't exist, create it
        entity = Intrigue::Model::Entity.create(attributes.merge(:project => project))
        entity.save
      end

      # Start the task_run
      task_id = start_task_run(project.id, nil, task_name, entity, options, handlers)
      status 200 if task_id

    # must be a string otherwise it can be interpreted as a status code
    task_id.to_s
    end

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

    ###                          ###
    ### Per-Project Scan Results ###
    ###                          ###

    # Show the results in a JSON
    get '/:project/scan_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_json if @result
    end

    # Show the results in a CSV
    get '/:project/scan_results/:id.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_csv if @result
    end

    # Show the results in a graph format
    get '/:project/scan_results/:id/graph.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_graph_csv if @result
    end

    # Show the results in a graph format
    get '/:project/scan_results/:id/graph.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_graph_json if @result
    end

    # Show the results in a graph format
    get '/:project/scan_results/:id/graph.gexf/?' do
      content_type 'text/plain'
      result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless result

      # Generate a list of entities and task runs to work through
      @entity_pairs = []
      result.task_results.each do |task_result|
        task_result.entities.each do |entity|
          @entity_pairs << {:task_result => task_result, :entity => entity}
        end
      end

      erb :'scans/gexf', :layout => false
    end

    # Determine if the scan run is complete
    get '/:project/scan_results/:id/complete' do
      result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])

      # immediately return false unless we find the scan result
      return false unless result

      # check for completion
      return "true" if result.complete

    # default to false
    false
    end

    # Endpoint to start a task run programmatically
    post '/:project/scan_results/?' do
      scan_result_info = JSON.parse(request.body.read) if request.content_type == "application/json"

      project_name = scan_result_info["project_name"]
      scan_type = scan_result_info["scan_type"]
      entity_hash = scan_result_info["entity"]
      depth = scan_result_info["depth"].to_i
      options = scan_result_info["options"]
      handlers = scan_result_info["handlers"]

      # Get the project
      project = Intrigue::Model::Project.first(:name => project_name)
      unless project # If the project didn't exist, create it
        project = Intrigue::Model::Project.create(:name => project_name)
      end

      # Try to find the entity
      entity = Intrigue::Model::Entity.scope_by_project(project_name).first(
        :name => entity_hash['name'],
        :type => entity_hash['type']
      ) # If it doesn't exist, create it
      unless entity
        entity = Intrigue::Model::Entity.create({
          :type => "Intrigue::Entity::#{entity_hash['type']}",
          :name => entity_hash['name'],
          :details => entity_hash['details'],
          :project => project
        })
      end

      # Set up the ScanResult object
      scan_result = Intrigue::Model::ScanResult.create({
        :scan_type => scan_type,
        :name => "#{scan_type}",
        :base_entity => entity,
        :depth => depth,
        :filter_strings => "",
        :handlers => handlers,
        :logger => Intrigue::Model::Logger.create(:project => project),
        :project => project
      })

      id = scan_result.start
    end

    # Get the scan log
    get '/:project/scan_results/:id/log' do
      content_type 'application/json'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless @result

      {:data => @result.log}.to_json
    end

  end
end
