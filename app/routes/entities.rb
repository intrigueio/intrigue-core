class IntrigueApp < Sinatra::Base
  namespace '/v1' do
    get '/entities' do
      erb :entities
    end
  end
end
