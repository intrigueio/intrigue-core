class CoreApp < Sinatra::Base

  get '/:project/entities' do

    params[:search_string] == "" ? @search_string = nil : @search_string = params[:search_string]
    params[:entity_types] == "" ? @entity_types = nil : @entity_types = params[:entity_types]
    params[:include_hidden] == "on" ? @include_hidden = true : @include_hidden = false
    params[:include_unscoped] == "on" ? @include_unscoped = true : @include_unscoped = false
    params[:only_enriched] == "on" ? @only_enriched = true : @only_enriched = false
    params[:grouped_entities] == "on" ? @grouped_entities = true : @grouped_entities = false

    (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1
    (params[:count] != "" && params[:count].to_i > 0) ? @count = params[:count].to_i : @count = 100

    @selected_entities = Intrigue::Core::Model::Entity.scope_by_project(@project_name)
    @selected_entities = @selected_entities.where(:type => @entity_types) if @entity_types
    @selected_entities = _tokenized_search(@search_string, @selected_entities) if @search_string
    @selected_entities = @selected_entities.where(:enriched => true) if  @only_enriched

    # create a calculated url with our parameters
    @calculated_url = "/#{h @project_name}/entities?search_string=#{h @search_string}&include_hidden=#{@include_hidden ? 'on' : 'off'}&include_unscoped=#{@include_unscoped ? 'on' : 'off'}&grouped_entities=#{@grouped_entities ? 'on' : 'off'}&#{@entity_types.map{|x| "entity_types[]=#{h x}" }.join("&") if @entity_types}"

    if params[:export] == "csv"

      content_type 'application/csv'
      attachment "#{@project_name}.csv"
      result = ""
      @selected_entities.paged_each(:rows_per_fetch => 300){ |e| result << "#{e.export_csv}\n" }
      return result

    elsif params[:export] == "json"

      content_type 'application/json'
      attachment "#{@project_name}.json"
      result = []
      @selected_entities.paged_each(:rows_per_fetch => 300){ |e| result << "#{e.export_json}" }
      return result.to_json

    else # normal page

     @selected_entities = @selected_entities.paginate(@page, @count).order(:name)
     alias_group_ids = @selected_entities.select_map(:alias_group_id).uniq
     @alias_groups = Intrigue::Core::Model::AliasGroup.where({:id => alias_group_ids })
     erb :'entities/index'

    end

   end


  ###                      ###
  ### Per-Project Entities ###
  ###                      ###

  get "/:project/entities/:id.csv" do
    content_type 'text/plain'
    @entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params[:id].to_i)
    attachment "#{@project_name}_#{@entity.id}.csv"
    @entity.export_csv
  end

  get "/:project/entities/:id.json" do
    content_type 'application/json'
    @entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params[:id].to_i)
    attachment "#{@project_name}_#{@entity.id}.json"
    @entity.export_json
  end


 get '/:project/entities/:id' do
   @entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
   return "No such entity in this project" unless @entity

   @task_classes = Intrigue::TaskFactory.list

   erb :'entities/detail'
  end

    get '/:project/entities/:id/delete' do
      entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless entity
      entity.deleted = true
      entity.save

      redirect request.referrer
    end

    get '/:project/entities/:id/delete_children' do
      entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params[:id])
      return "No such entity in this project" unless entity
      #entity.deleted = true
      #entity.save

      Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).where(:base_entity => entity).each do |t|
        t.entities.each { |e| e.deleted = true; e.save }
      end

      redirect request.referrer
    end


    private

    def _tokenized_search(search_string, selected_entities)

      # Simple tokenized search......
      if search_string && search_string.length > 0
        #tokens = search_string.split("'")
        tokens = search_string.split("|")
        tokens.each do |t|
          if t =~ /^!/ || t =~ /^~/ || t =~ /^-/ # exclude whatever comes next
            ss = t[1..-1] # pull the token and remove any single quotes
            # check for a
            if ss =~ /^name:/
              ss.gsub!(/^name:/,"")
              selected_entities = selected_entities.exclude(Sequel.ilike(:name, "%#{ss}%"))
            else
              selected_entities = selected_entities.exclude(Sequel.ilike(:name, "%#{ss}%"))
            end
          else # just a normal search string
            ss = t
            if ss =~ /^name:/
              ss.gsub!(/^name:/,"")
              selected_entities = selected_entities.where(Sequel.ilike(:name, "%#{ss}%"))
            else
              selected_entities = selected_entities.where(Sequel.ilike(:name, "%#{ss}%"))
            end
          end
        end
      end

    selected_entities
    end

end
