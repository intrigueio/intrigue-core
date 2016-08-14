class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    post '/:project/entities' do
      @project_name = params[:project]
      @entity_type = params[:entity_type]
      @entity_name = params[:entity_name]
      ## We have some very rudimentary searching capabilities here
      ##
      ## TODO - these should be fleshed out so we can actually use the entities page
      ##
      scoped_entities = Intrigue::Model::Entity.scope_by_project(@project_name)
      if
        entity_type_string = eval("Intrigue::Entity::#{@entity_type}")
        @entities = scoped_entities.all(:type.like => entity_type_string).page(params[:page], :per_page => 50)
      elsif @entity_name
        @entities = scoped_entities.all(:name.like => "%#{@entity_name}%").page(params[:page], :per_page => 50)
      else
        @entities = scoped_entities.page(params[:page], :per_page => 50)
      end

      erb :'entities/index'
    end

    get '/:project/entities' do
      @project_name = params[:project]
      @entities = Intrigue::Model::Entity.scope_by_project(@project_name).page(params[:page], :per_page => 50)
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
