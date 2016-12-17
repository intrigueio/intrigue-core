class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    # graph
    get '/:project/graph' do
      @json_uri = "#{request.url}.json"
      erb :'graph'
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
      @entities = current_project.entities

      @persons  = []
      @applications = []
      @services = []
      @hosts = []
      @networks = []

      @entities.each do |item|
        @persons << item if item.kind_of? Intrigue::Entity::Person
        @applications << item if item.kind_of? Intrigue::Entity::Uri
        @services << item if item.kind_of? Intrigue::Entity::NetSvc
        @hosts << item if item.kind_of?(Intrigue::Entity::IpAddress) || item.kind_of?(Intrigue::Entity::DnsRecord)
        @networks << item if item.kind_of? Intrigue::Entity::NetBlock
      end

      erb :'dossier'
    end

  end
end
