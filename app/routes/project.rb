class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/:project/start' do
      @project = Intrigue::Model::Project.first(:name => @project_name)

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

    # graph
    get '/:project/graph/generated_at' do
      "#{Intrigue::Model::Project.first(:name => @project_name).graph_generated_at}"
    end


    # graph
    get '/:project/graph/meta' do
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

  end
end
