  # Scan
  get '/scan/?' do
    erb :scan
  end

  post '/interactive/scan' do

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

    depth = @params["depth"].to_i if @params["depth"]
    name = @params["name"] || "default"

    # Do the scan
    id = SecureRandom.uuid
    x = Intrigue::Scanner::SimpleScan.new
    x.class.perform_async entity, id, name, depth

    # Redirect to display the log
    redirect "/v1/scan_runs/#{id}"
  end


    # Show the results in a human readable format
    get '/scan_runs/:id' do

      # Get the log
      log = $intrigue_redis.get("scan:#{params[:id]}")
      reversed_log = log.split("\n").reverse.join("\n") if log

      @scan_log = reversed_log
=begin
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
=end
      erb :scan_run
    end
