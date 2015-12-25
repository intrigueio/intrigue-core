class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/entities' do
      @entities = Intrigue::Model::Entity.page(params[:page], :per_page => 100)
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
