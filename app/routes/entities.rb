class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    # Return a JSON array of all entity type
    get '/entity_types.json' do
      Intrigue::Model::Entity.descendants.map {|x| x.new.type_string }.to_json
    end

    get '/entities' do
      if params[:type]
        entity_type = eval "Intrigue::Entity::#{params[:type]}"
        @entities = Intrigue::Model::Entity.all(:type.like => entity_type).page(params[:page], :per_page => 100)
      else
        @entities = Intrigue::Model::Entity.page(params[:page], :per_page => 100)
      end
      erb :'entities/index'
    end

    get '/entities/:id.csv' do
      @entity = Intrigue::Model::Entity.get(params[:id])
      @entity.export_csv
    end

    get '/entities/:id.json' do
      @entity = Intrigue::Model::Entity.get(params[:id])
      @entity.export_json
    end

   get '/entities/:id' do
      @entity = Intrigue::Model::Entity.get(params[:id])

      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort

      erb :'entities/detail'
    end

  end
end
