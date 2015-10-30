class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper

  namespace '/v1/?' do

    get '/task/?' do

      @entity = Intrigue::Model::Entity.get params["entity_id"] if params["entity_id"]
      @task_result = Intrigue::Model::TaskResult.get params["task_result_id"] if params["task_result_id"]
      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort
      #@running_task_results = Intrigue::Model::TaskResult.all(:timestamp_end => nil)
      @completed_task_results = Intrigue::Model::TaskResult.all

      erb :'tasks/index'
    end

    # Export All Data
    get '/task_results.json/?' do
      raise "Not implemented"
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/interactive/single/?' do

      # get the task name
      task_name = "#{@params["task"]}"
      type = @params["entity_type"]
      details = {:type => "Intrigue::Entity::#{type}"}

      # Construct the attributes hash from the parameters. Loop through each of the
      # parameters looking for things that look like attributes, and add them to our
      # details hash
      @params.each do |name,value|
        #puts "Looking at #{name} to see if it's an attribute"
        if name =~ /^attrib/
          details["#{name.gsub("attrib_","")}"] = "#{value}"
        end
      end

      # Construct the options hash from the parameters
      options = []
      @params.each do |name,value|
        if name =~ /^option/
          options << {
                      "name" => "#{name.gsub("option_","")}",
                      "value" => "#{value}"
                      }
        end
      end

      # Construct an entity from the data we have
      puts "details: #{details}"

      create_line = "Intrigue::Entity::#{type}.new(details)"
      puts "Calling: #{create_line}"

      entity = eval create_line
      entity.save

      # Start the task run!
      task_id = start_task_run(task_name, entity, options)

      redirect "/v1/task_results/#{task_id}"
    end

    # Create a task run from a json request
    post '/task_results/?' do

      # What we recieve should look like this:
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
      attributes = payload["entity"]["attributes"]
      entity = eval "Intrigue::Entity::#{type}.create(attributes)"
      entity.save

      # Generate a task id
      task_name = payload["task"]
      options = payload["options"]

      # Start the task _run
      task_id = start_task_run(task_name, entity, options)

      # Return a task id so the caller can store and look up results later
    task_id
    end

    # Accept the results of a task run (webhook POSTs here by default)
    post '/task_results/:id/?' do

      # Retrieve the request's body and parse it as JSON
      result = JSON.parse(request.body.read)

      # Do something with event_json
      job_id = result["id"]

      # Return status
      status 200 if result
    end

    # Get the results of a task run
    get "/task_results/:id.json/?" do
      content_type :json
      result = Intrigue::Model::TaskResult.get(params[:id])
      result.export_json if result
    end

    # Show the results in a human readable format
    get '/task_results/:id/?' do

      task_result_id = params[:id].to_i

      # Get the task result from the database, and fail cleanly if it doesn't exist
      @task_result = Intrigue::Model::TaskResult.get(task_result_id)
      return "Unknown Task ID" unless @task_result

      # Assuming it's available, display it
      if @task_result
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1/task/?task_result_id=#{@task_result.id}"
        @elapsed_time = "#{(@task_result.timestamp_end - @task_result.timestamp_start).to_i}" if @task_result.timestamp_end
      end

      erb :'tasks/task_result'
    end

    # Determine if the task run is complete
    get '/task_results/:id/complete/?' do

      x = Intrigue::Model::TaskResult.get(params[:id])

      if x
        return "true" if x.complete
      end

    false
    end

    # Get the task log
    get '/task_results/:id/log/?' do
      @result = Intrigue::Model::TaskResult.get(params[:id])
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
  end
end
