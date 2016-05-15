class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    ###          ###
    ### ENTITIES ###
    ###          ###

    # Return a JSON array of all entity type
    get '/entity_types.json' do
      Intrigue::Model::Entity.descendants.map {|x| x.new.type_string }.to_json
    end

    get '/entities/:id.csv' do
      @entity = Intrigue::Model::Entity.current_project.all(:id => params[:id]).first
      @entity.export_csv
    end

    get '/entities/:id.json' do
      @entity = Intrigue::Model::Entity.current_project.all(:id => params[:id]).first
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

      entity = Intrigue::Model::Entity.create(attributes)
      entity.save

      # Generate a task id
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]

      # Start the task _run
      task_id = start_task_run(task_name, entity, options,handlers)
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
      @task_result = Intrigue::Model::TaskResult.current_project.all(:id => params[:id]).first
      @task_result.export_csv
    end

    # Show the results in a CSV format
    get '/task_results/:id.tsv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.current_project.all(:id => params[:id]).first
      @task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/task_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::TaskResult.current_project.all(:id => params[:id]).first
      @result.export_json if @result
    end


    # Determine if the task run is complete
    get '/task_results/:id/complete/?' do
      # Get the task result and return unless it's false
      x = Intrigue::Model::TaskResult.current_project.all(:id => params[:id]).first
      return false unless x

      # if we got it, and it's complete, return true
      return "true" if x.complete

    # Otherwise, not ready yet, return false
    false
    end

    # Get the task log
    get '/task_results/:id/log/?' do
      @result = Intrigue::Model::TaskResult.current_project.all(:id => params[:id]).first
      erb :log
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

    # Show the results in a JSON
    get '/scan_results/:id.json/?' do
      content_type 'application/json'
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
      @result.export_json if @result
    end

    # Show the results in a CSV
    get '/scan_results/:id.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
      @result.export_csv if @result
    end

    # Show the results in a graph format
    get '/scan_results/:id/graph.csv/?' do
      content_type 'text/plain'
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
      @result.export_graph_csv if @result
    end

    # Show the results in a graph format
    get '/scan_results/:id/graph.gexf/?' do
      content_type 'text/plain'
      result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
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
      result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first

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

      scan_type = scan_result_info["scan_type"]
      entity = scan_result_info["entity"]
      options = scan_result_info["options"]
      handlers = scan_result_info["handlers"]

      # Construct an entity from the data we have
      entity = Intrigue::Model::Entity.create(
      {
        :type => "Intrigue::Entity::#{entity['type']}",
        :name => entity['name'],
        :details => entity['details'],
        :project => Intrigue::Model::Project.current_project
      })

      # Set up the ScanResult object
      scan_result = Intrigue::Model::ScanResult.create({
        :scan_type => scan_type,
        :name => "#{scan_type}",
        :base_entity => entity,
        :depth => 4,
        :filter_strings => "",
        :handlers => handlers,
        :logger => Intrigue::Model::Logger.create(:project => Intrigue::Model::Project.current_project),
        :project => Intrigue::Model::Project.current_project
      })

      #puts "CREATING SCAN RESULT: #{scan_result.inspect}"

      id = scan_result.start
    end

    # Get the task log
    get '/scan_results/:id/log' do
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
      erb :log
    end

  end
end
