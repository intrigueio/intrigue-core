class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    # Scan Webform
    get '/scan/?' do
      @scan_results = Intrigue::Model::ScanResult.current_project.page(params[:page])
      erb :'scans/index'
    end

    # Endpoint to start a task run from a webform
    post '/interactive/scan' do

      # Collect the scan parameters
      scan_name = "#{@params["scan_type"]} on #{@params["attrib_name"]}"
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
        :project => Intrigue::Model::Project.current_project
      })

      # Set up the ScanResult object
      scan_result = Intrigue::Model::ScanResult.create({
        :scan_type => scan_type,
        :name => scan_name,
        :base_entity => entity,
        :depth => scan_depth,
        :filter_strings => scan_filter_strings,
        :logger => Intrigue::Model::Logger.create(:project => Intrigue::Model::Project.current_project),
        :project => Intrigue::Model::Project.current_project
      })

      scan_result.start

      # Redirect to display the details
      redirect "/v1/scan_results/#{scan_result.id}"
    end

    # Show the results in a human readable format
    get '/scan_results/:id/?' do
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first
      return "Unknown Scan Result" unless @result
      erb :'scans/scan_result'
    end

    # Show the results in a human readable format
    get '/scan_results/:id/profile/?' do
      @result = Intrigue::Model::ScanResult.current_project.all(:id => params[:id]).first

      @persons  = []
      @applications = []
      @services = []
      @hosts = []
      @networks = []

      @result.entities.each do |item|
        @persons << item if item.kind_of? Intrigue::Entity::Person
        @applications << item if item.kind_of? Intrigue::Entity::Uri
        @services << item if item.kind_of? Intrigue::Entity::NetSvc
        @hosts << item if item.kind_of?(Intrigue::Entity::IpAddress) || item.kind_of?(Intrigue::Entity::DnsRecord)
        @networks << item if item.kind_of? Intrigue::Entity::NetBlock
      end

      erb :'scans/profile'
    end

  end
end
