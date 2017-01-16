class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    post '/:project/entities' do
      @entity_name = params[:entity_name]
      @entity_types = params[:entity_types]
      @page_id = params[:page]

      ## We have some very rudimentary searching capabilities here
      x = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false)
      x = x.where(:type => @entity_types) if @entity_types

      if @entity_name
        @entities = x.where(Sequel.ilike(:name, "%#{@entity_name}%"))
      else
        @entities = x
      end
      
      erb :'entities/index'
    end

    get '/:project/entities' do
      @entity_name = params[:entity_name]
      @entity_types = params[:entity_types]
      @page_id = params[:page]

      ## We have some very rudimentary searching capabilities here
      x = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false)
      x = x.where(:type => @entity_types) if @entity_types

      if @entity_name
        @entities = x.where(Sequel.ilike(:name, "%#{@entity_name}%"))
      else
        @entities = x
      end

      erb :'entities/index'
    end


   get '/:project/entities/:id' do
     @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
     return "No such entity in this project" unless @entity

     @task_classes = Intrigue::TaskFactory.list

     erb :'entities/detail'
    end

    get '/:project/entities/:id/delete' do
      entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless entity
      entity.deleted = true
      entity.save
    true
    end

    get '/:project/entities/:id/delete_children' do
      entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless entity
      entity.deleted = true
      entity.save

      Intrigue::Model::TaskResult.scope_by_project(@project_name).where(:base_entity => entity).each do |t|
        t.entities.each { |e| e.deleted = true; e.save }
      end

    true
    end


  end
end
