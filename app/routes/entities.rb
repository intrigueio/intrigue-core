class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/:project/entities/meta' do
      @result_count = 100

      params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
      params[:entity_types] == "" ? @entity_types = nil : @entity_types = params[:entity_types]
      (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

      selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false).order(:name)

      ## Filter if we have a type
      selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

      ## We have some very rudimentary searching capabilities here
      selected_entities = selected_entities.where(Sequel.|(
        Sequel.ilike(:name, "%#{@search_string}%"),
        Sequel.ilike(:details_raw, "%#{@search_string}%"))) if @search_string

      # Do the meta-analysis
      @entities = []
      selected_entities.each do |se|
        alias_map = [se] | se.aliases.map{|a| a}

        merged = false
        @entities.each do |e|
          e.each do |x|
            if alias_map.include? x
              e = e | alias_map
              merged = true
            end
          end
        end
        
        @entities << alias_map unless merged
      end

      erb :'entities/index_meta'
    end

    get '/:project/entities' do
      @result_count = 100

      params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
      params[:entity_types] == "" ? @entity_types = nil : @entity_types = params[:entity_types]
      (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

      selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).where(:deleted => false).order(:name)

      ## Filter if we have a type
      selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

      ## We have some very rudimentary searching capabilities here
      selected_entities = selected_entities.where(Sequel.|(
        Sequel.ilike(:name, "%#{@search_string}%"),
        Sequel.ilike(:details_raw, "%#{@search_string}%"))) if @search_string

      # PAGINATE
      @entities_count = selected_entities.count
      @entities = selected_entities.extension(:pagination).paginate(@page,@result_count)

      erb :'entities/index'
    end

  get '/:project/entities.csv' do
    content_type 'text/csv'

    project = Intrigue::Model::Project.first(:name => @project_name)
    export = Intrigue::Model::ExportCsv.create(:project_id => project.id)

    export.generate

  export.contents
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
