class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    get '/entities' do
      erb :'entities/index'
    end

    get '/entities/:id' do
      @entity = Intrigue::Model::Entity.find(params[:id])
      erb :'entities/detail'
    end

  end
end
