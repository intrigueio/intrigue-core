class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    ###               ###
    ### System MGMT   ###
    ###               ###

    # save the config
    post '/system' do

      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      params.each {|k,v| $intrigue_config.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/ }
      $intrigue_config.save

      redirect '/v1/admin/config'  # handy if we're in a browser
    end

    ###                ###
    ### Project MGMT   ###
    ###                ###

    # save the config
    post '/project' do
      project_name = "#{params["project_name"]}"

      # create the project unless it exists
      unless Intrigue::Model::Project.first(:name => project_name)
        Intrigue::Model::Project.create(:name => project_name)
      end

      # set the current session variable
      session["project_name"] = project_name
      response.set_cookie "project_name", :value => project_name

      redirect '/v1/scan' # handy if we're in a browser
    end

    # save the config
    post '/project/delete' do
      project_name = "#{params["project_name"]}"
      project = Intrigue::Model::Project.first(:name => project_name)

      # create the project unless it exists
      if project
        project.destroy!

        # recreate the default project if we've removed
        if project_name == "Default"
          Intrigue::Model::Project.create(:name => "Default")
        end

        # move us to the default project if we removed our current_project
        if project_name == session["project_name"]
          session["project_name"] = "Default"
          response.set_cookie "project_name", :value => "Default"
        end

      end

      redirect '/v1/' # handy if we're in a browser
    end


    ###          ###
    ### ENTITIES ###
    ###          ###

    # Return a JSON array of all entity type
    get '/entity_types.json' do
      Intrigue::Model::Entity.descendants.map {|x| x.new.type_string }.to_json
    end

    get '/entities/:id.csv' do
      @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      @entity.export_csv
    end

    get '/entities/:id.json' do
      @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      @entity.export_json
    end

    ###       ###
    ### TASKS ###
    ###       ###

    # Create a task result from a json request
    post '/task_results/?' do

      # What we receive should look like this:
      #
      #payload = {
      #  "project_name" => project_name,
      #  "task" => task_name,
      #  "entity" => entity_hash,
      #  "options" => options_list,
      #}

      # Parse the incoming request
      payload = JSON.parse(request.body.read) if request.content_type == "application/json"

      ### don't take any shit
      return nil unless payload

      # Construct an entity from the entity_hash provided
      type = payload["entity"]["type"]
      attributes = payload["entity"].merge("type" => "Intrigue::Entity::#{type}")

      # get the details from the payload
      project_name = payload["project_name"] || "Default"
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]

      project = Intrigue::Model::Project.get(:name => project_name)
      entity = Intrigue::Model::Entity.create(attributes.merge(:project => project))
      entity.save

      # Start the task _run
      task_id = start_task_run(project.id, nil, task_name, entity, options, handlers)
      status 200 if task_id

    # must be a string otherwise it can be interpreted as a status code
    task_id.to_s
    end

    # Accept the results of a task run
    post '/task_results/:id/?' do
      # Retrieve the request's body and parse it as JSON
      result = JSON.parse(request.body.read)
      # Do something with event_json
      job_id = result["id"]
      # Return status
      status 200 if result
    end

    # Export All task results
    get '/task_results.json/?' do
      raise "Not implemented"
    end

    # Show the results in a CSV format
    get '/task_results/:id.csv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @task_result.export_csv
    end

    # Show the results in a CSV format
    get '/task_results/:id.tsv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/task_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_json if @result
    end


    # Determine if the task run is complete
    get '/task_results/:id/complete/?' do
      # Get the task result and return unless it's false
      x = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return false unless x

      # if we got it, and it's complete, return true
      return "true" if x.complete

    # Otherwise, not ready yet, return false
    false
    end

    # Get the task log
    get '/task_results/:id/log/?' do
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless @result

      {:data => @result.log}.to_json
    end

    # Export All Tasks
    get '/tasks.json/?' do
      tasks = []
       Intrigue::TaskFactory.list.each do |t|
          tasks << t.send(:new).metadata
      end
    tasks.to_json
    end

    # Export a single task
    get '/tasks/:id.json/?' do
      task_name = params[:id]
      Intrigue::TaskFactory.create_by_name(task_name).metadata.to_json
    end

    ###       ###
    ### SCANS ###
    ###       ###

    # Export All Tasks
    get '/scans.json/?' do
      scans = []
       Intrigue::ScanFactory.list.each do |s|
          scans << s.send(:new).metadata
      end
    scans.to_json
    end

    # Show the results in a JSON
    get '/scan_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_json if @result
    end

    # Show the results in a CSV
    get '/scan_results/:id.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_csv if @result
    end

    # Show the results in a graph format
    get '/scan_results/:id/graph.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      @result.export_graph_csv if @result
    end

    # Show the results in a graph format
    get '/scan_results/:id/graph.gexf/?' do
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
    get '/scan_results/:id/complete' do
      result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])

      # immediately return false unless we find the scan result
      return false unless result

      # check for completion
      return "true" if result.complete

    # default to false
    false
    end

    # Endpoint to start a task run programmatically
    post '/scan_results/?' do

      scan_result_info = JSON.parse(request.body.read) if request.content_type == "application/json"

      project_name = scan_result_info["project_name"]
      scan_type = scan_result_info["scan_type"]
      entity = scan_result_info["entity"]
      options = scan_result_info["options"]
      handlers = scan_result_info["handlers"]

      # Get the project
      p = Intrigue::Model::Project.first(:name => project_name)

      # Construct an entity from the data we have
      entity = Intrigue::Model::Entity.create(
      {
        :type => "Intrigue::Entity::#{entity['type']}",
        :name => entity['name'],
        :details => entity['details'],
        :project => p
      })

      # Set up the ScanResult object
      scan_result = Intrigue::Model::ScanResult.create({
        :scan_type => scan_type,
        :name => "#{scan_type}",
        :base_entity => entity,
        :depth => 4,
        :filter_strings => "",
        :handlers => handlers,
        :logger => Intrigue::Model::Logger.create(:project => p),
        :project => p
      })

      #puts "CREATING SCAN RESULT: #{scan_result.inspect}"

      id = scan_result.start
    end

    # Get the scan log
    get '/scan_results/:id/log' do
      @result = Intrigue::Model::ScanResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless @result

      {:data => @result.log}.to_json
    end

  end
end
