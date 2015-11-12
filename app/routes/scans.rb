class IntrigueApp < Sinatra::Base
  namespace '/v1/?' do

  # Scan
  get '/scan/?' do
    @scan_results = Intrigue::Model::ScanResult.all
    erb :'scans/index'
  end

  # Endpoint to start a task run from a webform
  post '/interactive/scan' do

    # Collect the scan parameters
    scan_name = @params["scan_name"] || "default"
    scan_type = "#{@params["scan_type"]}"
    scan_depth = @params["scan_depth"].to_i || 3
    scan_filter_strings = @params["scan_filter_strings"]

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
    entity = Intrigue::Model::Entity.create(
    {
      :type => "Intrigue::Entity::#{@params["entity_type"]}",
      :name => "#{@params["attrib_name"]}",
      :details => entity_details,
      :task_result_id => -1
    })

    # Set up the ScanResult object
    scan_result = Intrigue::Model::ScanResult.create({
      :scan_type => scan_type,
      :name => scan_name,
      :base_entity => entity,
      :depth => scan_depth,
      :filter_strings => scan_filter_strings
    })

    ###
    # Create the Scanner
    ###
    if scan_result.scan_type == "simple"
      scan = Intrigue::Scanner::SimpleScan.new
    elsif scan_result.scan_type == "internal"
      scan = Intrigue::Scanner::InternalScan.new
    else
      raise "Unknown scan type"
    end

    # Kick off the scan
    scan.class.perform_async scan_result.id

    # Redirect to display the details
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
    @scan_result = Intrigue::Model::ScanResult.get(params[:id])
    erb :'scans/scan_result'
  end

  # Determine if the scan run is complete
  get '/scan_results/:id/complete' do
    x = Intrigue::Model::ScanResult.get(params[:id])

    if x
      return "true" if x.complete
    end

  false
  end

  # Get the task log
  get '/scan_results/:id/log' do
    @result = Intrigue::Model::ScanResult.get(params[:id])
    erb :log
  end


end
end
