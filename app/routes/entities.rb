class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/:project/entities' do
      @search_string = params[:search_string]
      @entity_types = params[:entity_types]
      @page_id = params[:page]

      ## We have some very rudimentary searching capabilities here
      x = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false)
      x = x.where(:type => @entity_types) if @entity_types

      if @search_string
        selected_entities = x.where(Sequel.ilike(:details, "%#{@search_string}%") | Sequel.ilike(:name, "%#{@search_string}%"))
      else
        selected_entities = x
      end

      @entities = selected_entities #.to_a.select{ |x| x if x.primary }

      erb :'entities/index'
    end

  get '/:project/entities.csv' do

    content_type 'text/csv'
    x = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false)

    out = ""
    x.each do |entity|
      alias_string = entity.aliases.each{|a| "#{a.type_string}##{a.name}" }.join(" | ")
      out << "#{entity.type_string},#{entity.name},#{alias_string},#{entity.detail_string}\n"
    end

  out
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
      #entity.deleted = true
      #entity.save

      Intrigue::Model::TaskResult.scope_by_project(@project_name).where(:base_entity => entity).each do |t|
        t.entities.each { |e| e.deleted = true; e.save }
      end

    true
    end


  end
end
