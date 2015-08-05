class IntrigueApp < Sinatra::Base
  namespace '/v1/?' do

  # Export All Data
  get '/task_runs.json' do

    # Clear all results
    namespace = "result"
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
  get '/task_runs' do
    namespace = "result"
    keys = $intrigue_redis.keys("#{namespace}*")

    unsorted_results = []
    keys.each do |key|
      unsorted_results << JSON.parse($intrigue_redis.get(key))
    end

    @task_results = unsorted_results.sort_by{ |k| k["timestamp_start"] }.reverse

    erb :task_runs
  end

  # Helper to construct the request to the API when the application is used interactively
  post '/interactive/single' do

    # Generate a task id
    task_id = SecureRandom.uuid

    # This is pretty ugly and compensates for our lack of a local DB.
    # We need to convert form inputs into a reasonable
    # request. This means collecting attributes and options and arranging them
    # in way that the application can handle. Prepare yourself.

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

    # Construct an entity from the data we have
    entity = { :type => @params["entity_type"], :attributes => attribs }


    # Construct the options hash from the parameters
    options = []
    @params.each do |name,value|
      #puts "Looking at #{name} to see if it's an option"
      if name =~ /^option/
        options << {
                    "name" => "#{name.gsub("option_","")}",
                    "value" => "#{value}"
                    }
      end
    end

    # Reconstruct the request as a hash, which we'll send to ourself as an API
    # request (as json). When we're using in interactive mode, we'll hardcode the
    # webhook so that we post back to ourselves
    x = { "task" => @params["task"],
          "options" => options,
          "entity" => entity,
          "hook_uri" => "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1/task_runs/#{task_id}"
    }

    start_task_run(task_id, x)

    redirect "/v1/task_runs/#{task_id}"
  end

  # Create a task run from a json request
  post '/task_runs' do

    # Generate a task id
    task_id = SecureRandom.uuid

    # Parse the incoming request
    task_run_info = JSON.parse(request.body.read) if request.content_type == "application/json"

    ### XXX - do we need @params here?

    return nil unless task_run_info

    # Sensible default if the hook URI not specified (this is the case with most CLI stuff including core-cli)
    local_hook = "#{$intrigue_server_uri}/v1/task_runs/#{task_id}"
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
  post '/task_runs/:id' do

    # Retrieve the request's body and parse it as JSON
    result = JSON.parse(request.body.read)

    # Do something with event_json
    #puts "Got result:\n #{result}"
    job_id = result["id"]

    # Persist the result
    $intrigue_redis.set("result:#{job_id}", result.to_json)

    # Return status
    status 200 if result
  end

  # Get the results of a task run
  get "/task_runs/:id.json" do
    content_type :json
    result = $intrigue_redis.get("result:#{params[:id]}")
    result if result
  end

  # Show the results in a human readable format
  get '/task_runs/:id' do

    # Get the log
    log = $intrigue_redis.get("task:#{params[:id]}")
    reversed_log = log.split("\n").reverse.join("\n") if log

    # remove newline
    #reversed_log[0]=''

    @task_log = reversed_log

    # Get the result from Redis
    result = $intrigue_redis.get("result:#{params[:id]}")
    if result # Assuming it's available, display it
      @task_run = JSON.parse(result)
      @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1?task_name=#{@task_run["task_name"]}&type=#{@task_run["entity"]["type"]}&#{@task_run["entity"]["attributes"].collect { |k, v| "attrib_#{k}=#{v}" }.join("?")}"
      @elapsed_time = Time.parse(@task_run['timestamp_end']).to_i - Time.parse(@task_run['timestamp_start']).to_i
    else
      ## it'll just be empty for now
      @task_run = { 'entities' => [],
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

    erb :task_run
  end

  # Determine if the task run is complete
  get '/task_runs/:id/complete' do
    result = "false"
    if $intrigue_redis.get("result:#{params[:id]}")
      result = "true"
    end
  result
  end

  # Get the task log
  get '/task_runs/:id/log' do
    $intrigue_redis.get("task:#{params[:id]}")
  end

  # SHOW THE RESULTS W/ A VISUALIZATION
  get '/task_runs/:id/viz' do
    @task_id = params[:id]
    erb :task_run_viz
  end
end
end
