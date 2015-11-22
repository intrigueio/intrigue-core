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
      :filter_strings => scan_filter_strings,
      :logger => Intrigue::Model::Logger.create
    })

    scan_result.start

    # Redirect to display the details
    redirect "/v1/scan_results/#{scan_result.id}"
  end

  # Endpoint to start a task run programmatically
  post '/scan_results/?' do

    scan_result_info = JSON.parse(request.body.read) if request.content_type == "application/json"

    scan_type = scan_result_info["scan_type"]
    entity = scan_result_info["entity"]
    options = scan_result_info["options"]

    # Construct an entity from the data we have
    entity = Intrigue::Model::Entity.create(
    {
      :type => "Intrigue::Entity::#{entity['type']}",
      :name => entity['name'],
      :details => entity['details'],
      :task_result_id => -1
    })

    # Set up the ScanResult object
    scan_result = Intrigue::Model::ScanResult.create({
      :scan_type => scan_type,
      :name => "x",
      :base_entity => entity,
      :depth => 4,
      :filter_strings => "",
      :logger => Intrigue::Model::Logger.create
    })

    id = scan_result.start
  end

  # Show the results in a human readable format
  get '/scan_results/:id.json/?' do
    content_type 'application/json'
    @scan_result = Intrigue::Model::ScanResult.get(params[:id])
    @scan_result.export_json
  end

  # Show the results in a human readable format
  get '/scan_results/:id/?' do
    @scan_result = Intrigue::Model::ScanResult.get(params[:id])
    erb :'scans/scan_result'
  end

  # Determine if the scan run is complete
  get '/scan_results/:id/complete' do
    x = Intrigue::Model::ScanResult.get(params[:id])
    # immediately return false unless we find the scan result
    return false unless x
    # check for completion
    return "true" if x.complete
  # default to false
  false
  end

  # Get the task log
  get '/scan_results/:id/log' do
    @result = Intrigue::Model::ScanResult.get(params[:id])
    erb :log
  end

end
end
