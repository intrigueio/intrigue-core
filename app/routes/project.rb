class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/:project/start' do

      # if we receive an entity_id or a task_result_id, instanciate the object
      if params["entity_id"]
        @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params["entity_id"])
      end

      # If we've been given a task result...
      if params["result_id"]
        @task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params["result_id"])
        @entity = @task_result.base_entity
      end

      @task_classes = Intrigue::TaskFactory.list
      erb :'start'
    end

    # graph
    get '/:project/graph' do
      @json_uri = "#{request.url}.json"
      @graph_generated_at = Intrigue::Model::Project.first(:name => @project_name).graph_generated_at
      erb :'graph'
    end

    get '/:project/graph/reset' do
      p= Intrigue::Model::Project.first(:name => @project_name)
      p.graph_generation_in_progress = false
      p.save
      redirect "/v1/#{@project_name}/graph"
    end

    # Show the results in a gexf format
    get '/:project/graph.gexf/?' do
      content_type 'text/plain'
      result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless result

      # Generate a list of entities and task runs to work through
      @entity_pairs = []
      result.each do |task_result|
        task_result.entities.each do |entity|
          @entity_pairs << {:task_result => task_result, :entity => entity}
        end
      end

      erb :'gexf', :layout => false
    end

    # dossier
    get '/:project/dossier' do
      current_project = Intrigue::Model::Project.first(:name => @project_name)
      @entities = Intrigue::Model::Entity.where(:project_id => current_project.id).sort_by{|x| x.name }

      @persons = []
      @emails = []
      @phone_numbers = []
      @software_packages = []
      @services = []
      @ip_addresses = []
      @dns_records = []
      @networks = []
      @uris = []
      @ssl_certificates = []
      @other = []

      @entities.each do |item|
        if item.kind_of? Intrigue::Entity::Person
          @persons << item
        elsif item.kind_of? Intrigue::Entity::PhoneNumber
          @phone_numbers << item
        elsif item.kind_of? Intrigue::Entity::EmailAddress
          @emails << item
        elsif item.kind_of? Intrigue::Entity::SoftwarePackage
          @software_packages << item
        elsif item.kind_of? Intrigue::Entity::NetworkService
          @services << item
        elsif item.kind_of? Intrigue::Entity::IpAddress
          @ip_addresses << item
        elsif item.kind_of? Intrigue::Entity::DnsRecord
          @dns_records << item
        elsif item.kind_of? Intrigue::Entity::NetBlock
          @networks << item
        elsif item.kind_of? Intrigue::Entity::SslCertificate
          @ssl_certificates << item
        elsif item.kind_of? Intrigue::Entity::Uri
          @uris << item
        else
          @other << item
        end
      end

      erb :'dossier'
    end

  end
end
