class IntrigueApp < Sinatra::Base
  namespace '/v1' do

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
      @entities = Intrigue::Model::Entity.all(:project_id => current_project.id, :order => [:name])

      @persons  = []
      @applications = []
      @services = []
      @ip_addresses = []
      @dns_records = []
      @networks = []

      @entities.each do |item|
        @persons << item if item.kind_of? Intrigue::Entity::Person
        @applications << item if item.kind_of? Intrigue::Entity::Uri
        @applications << item if item.kind_of?(Intrigue::Entity::WebServer)
        @applications << item if item.kind_of?(Intrigue::Entity::WebApplication)
        @services << item if item.kind_of? Intrigue::Entity::NetworkService
        @ip_addresses << item if item.kind_of?(Intrigue::Entity::IpAddress)
        @dns_records << item if item.kind_of?(Intrigue::Entity::DnsRecord)
        @networks << item if item.kind_of? Intrigue::Entity::NetBlock
      end

      erb :'dossier'
    end

  end
end
