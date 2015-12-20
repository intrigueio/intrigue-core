class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper

  namespace '/v1/?' do

    get '/task/?' do

      @entity = Intrigue::Model::Entity.get params["entity_id"] if params["entity_id"]
      @task_result = Intrigue::Model::TaskResult.get params["task_result_id"] if params["task_result_id"]
      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort
      @task_results = Intrigue::Model::TaskResult.page(params[:page], :per_page => 10)

      erb :'tasks/index'
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/interactive/single/?' do

      # get the task name
      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]

      # Construct the attributes hash from the parameters. Loop through each of the
      # parameters looking for things that look like attributes, and add them to our
      # details hash
      entity_details = {}
      @params.each do |name,value|
        #puts "Looking at #{name} to see if it's an attribute"
        if name =~ /^attrib/
          entity_details["#{name.gsub("attrib_","")}"] = "#{value}"
        end
      end

      # Construct an entity from the data we have
      if entity_id
        entity = Intrigue::Model::Entity.get(entity_id)
      else
        entity = Intrigue::Model::Entity.create(
        {
          :type => "Intrigue::Entity::#{@params["entity_type"]}",
          :name => "#{@params["attrib_name"]}",
          :details => entity_details
        })
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

      # Start the task run!
      task_result_id = start_task_run(task_name, entity, options)
      task_result = Intrigue::Model::TaskResult.find(task_result_id).first

      entity.task_results << task_result
      entity.save

      redirect "/v1/task_results/#{task_result_id}"
    end


    # Export All Tasks
    get '/task_results.json/?' do
      raise "Not implemented"
    end

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

    # Show the results in a CSV format
    get '/task_results/:id.csv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.get(params[:id])
      @task_result.export_csv
    end

    # Show the results in a CSV format
    get '/task_results/:id.tsv/?' do
      content_type 'text/plain'
      @task_result = Intrigue::Model::TaskResult.get(params[:id])
      @task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/task_results/:id.json/?' do
      content_type 'application/json'
      @task_result = Intrigue::Model::TaskResult.get(params[:id])
      @task_result.export_json
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
      # Get the task result and return unless it's false
      x = Intrigue::Model::TaskResult.get(params[:id])
      return false unless x
      # if we got it, and it's complete, return true
      return "true" if x.complete

    # otherwise, not ready yet, return false
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
