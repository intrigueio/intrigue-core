class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper

  namespace '/v1/?' do

    # Export All Data
      get '/task_results.json' do

      # get all results
      namespace = "task_result"
      keys = $intrigue_redis.keys("#{namespace}*")

      results = []
      keys.each do |key|
        results << $intrigue_redis.get(key)
      end

      ### XXX - SECURITY - this needs to be escaped, or the individual
      ### results need to have their fields escaped. Noodle.
      results.to_json
    end

    # Existing task runs
    get '/task_results' do
      keys = $intrigue_redis.keys("task_result:*")

      unsorted_results = []
      keys.each do |key|
        begin
          unsorted_results << Intrigue::Model::TaskResult.find(key.split(":").last)
        rescue JSON::ParserError => e
          #puts "Parse Error: #{e}"
        end
      end

      @task_results = unsorted_results #.sort_by{ |k| k.timestamp_start }.reverse

      erb :task_results
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/interactive/single' do

      # Generate a task id
      task_id = SecureRandom.uuid

      # get the task name
      task_name = "#{@params["task"]}"

      # Construct the attributes hash from the parameters. Loop through each of the
      # parameters looking for things that look like attributes, and add them to our
      # attribs hash
      attribs = {}
      @params.each do |name,value|
        #puts "Looking at #{name} to see if it's an attribute"
        if name =~ /^attrib/
          attribs["#{name.gsub("attrib_","")}"] = "#{value}"
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
      entity = Intrigue::Model:: Entity.new @params["entity_type"], attribs
      entity.save

      # Start the task run!
      start_task_run(task_id, task_name, entity, options)

      redirect "/v1/task_results/#{task_id}"
    end

    # Create a task run from a json request
    post '/task_results' do

      # Generate a task id
      task_id = SecureRandom.uuid

      # Create the task result in the DB
      @task_result = Intrigue::Model::TaskResult.new task_id, "x"
      @task_result.save

      # Parse the incoming request
      task_run_info = JSON.parse(request.body.read) if request.content_type == "application/json"

      ### XXX - do we need @params here?

      return nil unless task_run_info

      # Sensible default if the hook URI not specified (this is the case with most CLI stuff including core-cli)
      local_hook = "#{$intrigue_server_uri}/v1/task_results/#{task_id}"
      task_run_info["hook_uri"] = local_hook unless task_run_info["hook_uri"]

      ###
      ### XXX SECURITY
      ###
      ### Do some upfront sanity checking of the user parameters
      ###
      return nil unless Intrigue::TaskFactory.include?(task_run_info["task"])

      # Start the task _run
      start_task_run task_id, task_run_info

      # Return a task id so the caller can store and look up results later
    task_id
    end

    # Accept the results of a task run (webhook POSTs here by default)
    post '/task_results/:id' do

      # Retrieve the request's body and parse it as JSON
      result = JSON.parse(request.body.read)

      # Do something with event_json
      #puts "Got result:\n #{result}"
      job_id = result["id"]

      # Persist the result
      $intrigue_redis.set("task_result:#{job_id}", result.to_json)

      # Return status
      status 200 if result
    end

    # Get the results of a task run
    get "/task_results/:id.json" do
      content_type :json
      result = Intrigue::Model::TaskResult.find params[:id] #$intrigue_redis.get("task_result:#{params[:id]}")
      result if result
    end

    # Show the results in a human readable format
    get '/task_results/:id' do
      # Get the task result from the database, and fail cleanly if it doesn't exist
      @task_result = Intrigue::Model::TaskResult.find(params[:id])

      # Catch any issues
      return "Unknown Task ID" unless @task_result

      # Separate out the task log
      @task_log = @task_result.log

      #puts "TASK RESULT #{@task_result}"

      # Assuming it's available, display it
      if @task_result
        @rerun_uri = "TODO" #"#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1?task_name=#{@task_result.task_name}&type=#{@task_result.entity.type}&#{@task_result.entity.attributes.collect { |k, v| "attrib_#{k}=#{v}" }.join("?")}"
        @elapsed_time = Time.parse(@task_result.timestamp_end).to_i - Time.parse(@task_result.timestamp_start).to_i
      else
        ## it'll just be empty for now
        @task_result = { 'entities' => [],
                      'task_name'  => "please wait...",
                      'entity'  => {'type' => "please wait...", 'attributes' => {}},
                      'timestamp_start'  => "please wait...",
                      'timestamp_end'  => "please wait...",
                      'id' => "please wait..."
                    }

        @elapsed_time = "please wait..."

        # and get us as close as we can
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1?"
      end

      erb :task_result
    end

    # Determine if the task run is complete
    get '/task_results/:id/complete' do
      return "true" if Intrigue::Model::TaskResult.find(params[:id])
    "false"
    end

    # Get the task log
    get '/task_results/:id/log' do
      #$intrigue_redis.get("task_result_log:#{params[:id]}")
      Intrigue::Model::TaskResult.find(params[:id]).log.to_s
    end

    # Export All Tasks
    get '/tasks.json' do
      tasks = []
       Intrigue::TaskFactory.list.each do |t|
          tasks << t.send(:new).metadata
      end
    tasks.to_json
    end

    # Export a single task
    get '/tasks/:id.json' do
      task_name = params[:id]
      Intrigue::TaskFactory.create_by_name(task_name).metadata.to_json
    end
  end
end
