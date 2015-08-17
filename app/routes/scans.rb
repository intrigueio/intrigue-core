class IntrigueApp < Sinatra::Base
  namespace '/v1/?' do

  # Scan
  get '/scan/?' do

    # Get details on the scan results so we can display them
    scan_ids = $intrigue_redis.keys("scan_result:*").reverse
    @scan_results = scan_ids.map{|id| Intrigue::Model::ScanResult.find id.split(":").last }

    puts "Got Scan Results: #{@scan_results}"

    erb :scan
  end

  # Endpoint to start a task run from a webform
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
    entity = Intrigue::Model::Entity.new @params["entity_type"],attribs
    entity.save

    # Create a unique identifier
    scan_id = SecureRandom.uuid
    name = @params["name"] || "default"

    # Set up the scan result
    scan_result = Intrigue::Model::ScanResult.new scan_id, name
    scan_result.depth = @params["depth"].to_i || "3"
    scan_result.scan_type = @params["scan_type"]
    scan_result.entity = entity

    # Save it!
    scan_result.save
    puts "scan_result: #{scan_result}"

    ###
    # Create the scanner object
    ###
    if scan_result.scan_type == "simple"
      scan = Intrigue::Scanner::SimpleScan.new
    elsif scan_result.scan_type == "internal"
      scan = Intrigue::Scanner::InternalScan.new
    else
      raise "Unknown scan type"
    end

    # Kick off the scan
    jid = scan.class.perform_async scan_result.id

    # Redirect to display the log
    redirect "/v1/scan_results/#{scan_result.id}"
  end

=begin
  # XXX - this needs to be reconfigured to match new perform_async parameters.

  # Endpoint to start a task run programmatically
  post '/scan_result/?' do

    scan_id = SecureRandom.uuid

    scan_result_info = JSON.parse(request.body.read) if request.content_type == "application/json"

    entity = scan_result_info["entity"]
    name = scan_result_info["name"]
    depth = scan_result_info["depth"]

    start_scan(scan_id, entity, name, depth)

  scan_id
  end
=end

  # Show the results in a human readable format
  get '/scan_results/:id/?' do

    @scan_result = Intrigue::Model::ScanResult.find(params[:id])
    @scan_log = @scan_result.log
    # Get the log
    #log = $intrigue_redis.get("scan:#{params[:id]}")
    #reversed_log = log.split("\n").reverse.join("\n") if log


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
    erb :scan_result
  end


end
end
