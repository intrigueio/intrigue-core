class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/entities' do
      erb :'entities/index'
    end

    get '/entities/:id' do
      @entity = Intrigue::Model::Entity.get(params[:id])

      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort

      erb :'entities/detail'
    end

  end
end
