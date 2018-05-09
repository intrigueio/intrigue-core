class IntrigueApp < Sinatra::Base

  get '/:project/entities' do
    @result_count = 100

    params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
    params[:entity_types] == "" ? @entity_types = nil : @entity_types = params[:entity_types]
    #params[:correlate] == "on" ? @correlate = true : @correlate = false
    params[:include_hidden] == "on" ? @include_hidden = true : @include_hidden = false
    (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

    #if @correlate # Handle entity coorelation

     selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).order(:name)

     ## filter if we have a type
     selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

     # search
     selected_entities = _tokenized_search(@search_string, selected_entities)

     # filter out hidden if requested
     selected_entities = selected_entities.where(:hidden => false) unless @include_hidden

     # Get the corresponding alias groups
     alias_group_ids = selected_entities.select_map(:alias_group_id).uniq
     alias_groups = Intrigue::Model::AliasGroup.where({:id => alias_group_ids })

     @alias_groups = alias_groups.extension(:pagination).paginate(@page,@result_count)

     @group_count = alias_groups.count
     @entity_count = selected_entities.count

     erb :'entities/index'
   end


  get '/:project/entities.csv' do
    content_type 'text/csv'

    params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
    params[:entity_types] == [""] ? @entity_types = nil : @entity_types = params[:entity_types]
    params[:include_hidden] == "on" ? @include_hidden = true : @include_hidden = false
    (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

    selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).order(:name)

    ## Filter if we have a type
    selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

    # Perform a simple tokenized search
    selected_entities = _tokenized_search(@search_string, selected_entities) if @search_string

    # filter out hidden if requested
    selected_entities = selected_entities.where(:hidden => false) unless @include_hidden

    out = ""
    out << "Type,Name,Alias Group,Details\n"
    selected_entities.each do |entity|
      alias_string = entity.alias_group.id if entity.alias_group
      out << "#{entity.type_string},#{entity.name},#{alias_string},#{entity.detail_string}\n"
    end

  out
  end

  get '/:project/entities.json' do
    content_type 'text/json'

    params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
    params[:entity_types] == [""] ? @entity_types = nil : @entity_types = params[:entity_types]
    params[:include_hidden] == "on" ? @include_hidden = true : @include_hidden = false
    (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

    selected_entities = Intrigue::Model::Entity.scope_by_project(@project_name).order(:name)

    ## Filter if we have a type
    selected_entities = selected_entities.where(:type => @entity_types) if @entity_types

    # Perform a simple tokenized search
    selected_entities = _tokenized_search(@search_string, selected_entities) if @search_string

    # filter out hidden if requested
    selected_entities = selected_entities.where(:hidden => false) unless @include_hidden

    out = []
    selected_entities.each do |entity|
      out << entity.to_hash
    end

  JSON.pretty_generate out
  end

  ###                      ###
  ### Per-Project Entities ###
  ###                      ###

  get "/:project/entities/:id.csv" do
    content_type 'text/plain'
    @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id].to_i)
    @entity.export_csv
  end

  get "/:project/entities/:id.json" do
    content_type 'application/json'
    @entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id].to_i)
    @entity.export_json
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

      redirect request.referrer
    end

    get '/:project/entities/:id/delete_children' do
      entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless entity
      #entity.deleted = true
      #entity.save

      Intrigue::Model::TaskResult.scope_by_project(@project_name).where(:base_entity => entity).each do |t|
        t.entities.each { |e| e.deleted = true; e.save }
      end

      redirect request.referrer
    end


    private

    def _tokenized_search(search_string, selected_entities)
      # Simple tokenized search......
      if search_string && search_string.length > 0
        tokens = search_string.split(" ")
        tokens.each do |t|
          if t =~ /^!/ || t =~ /^~/ || t =~ /^-/ # exclude whatever comes next
            ss = t[1..-1]
            # check for a
            if ss =~ /^name:/
              ss.gsub!(/^name:/,"")
              selected_entities = selected_entities.exclude(Sequel.ilike(:name, "%#{ss}%"))
            elsif ss =~ /^details:/
              ss.gsub!(/^details:/,"")
              selected_entities = selected_entities.exclude(Sequel.ilike(:details_raw, "%#{ss}%"))
            else
              selected_entities = selected_entities.exclude(Sequel.|(
                Sequel.ilike(:name, "%#{ss}%"),
                Sequel.ilike(:details_raw, "%#{ss}%")))
            end
          else # just a normal search string
            ss = t
            if ss =~ /^name:/
              ss.gsub!(/^name:/,"")
              selected_entities = selected_entities.where(Sequel.ilike(:name, "%#{ss}%"))
            elsif ss =~ /^details:/
              ss.gsub!(/^details:/,"")
              selected_entities = selected_entities.where(Sequel.ilike(:details_raw, "%#{ss}%"))
            else
              selected_entities = selected_entities.where(Sequel.|(
                Sequel.ilike(:name, "%#{t}%"),
                Sequel.ilike(:details_raw, "%#{t}%")))
            end
          end
        end
      end

    selected_entities
    end

end
