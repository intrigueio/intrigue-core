class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    post '/:project/entities' do
      @project_name = params[:project]

      ## We have some very rudimentary searching capabilities here
      ##
      ## TODO - these should be fleshed out so we can actually use the entities page
      ##
      if params[:entity_type]
        entity_type = eval "Intrigue::Entity::#{params[:entity_type]}"
        @entities = Intrigue::Model::Entity.scope_by_project(@project_name).all(:type.like => entity_type).page(params[:page], :per_page => 100)

      elsif params[:entity_name]
        entity_name = params[:entity_name]
        @entities = Intrigue::Model::Entity.scope_by_project(@project_name).all(:name.like => "%#{entity_name}%").page(params[:page], :per_page => 100)
        
      else
        @entities = Intrigue::Model::Entity.scope_by_project(@project_name).page(params[:page], :per_page => 100)
      end

      erb :'entities/index'
    end

    get '/:project/entities' do
      @project_name = params[:project]
      @entities = Intrigue::Model::Entity.scope_by_project(@project_name).page(params[:page], :per_page => 100)
      erb :'entities/index'
    end


   get '/:project/entities/:id' do
     @project_name = params[:project]
      @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless @entity

      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort

      erb :'entities/detail'
    end

  end
end
