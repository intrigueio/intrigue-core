class IntrigueApp < Sinatra::Base
  namespace '/v1' do
    namespace '/admin' do

      get '/?' do
        erb :"admin/index"
      end

      # TODO - kill this
      # Get rid of all existing task runs
      get '/clear/?' do

        # Clear the default queue
        Sidekiq::Queue.new.clear

        # Clear the retries
        rs = Sidekiq::RetrySet.new
        rs.size
        rs.clear

        # Clear the dead jobs
        ds = Sidekiq::DeadSet.new
        ds.size
        ds.clear

        Intrigue::Model::Entity.current_project.destroy
        Intrigue::Model::TaskResult.current_project.destroy
        Intrigue::Model::ScanResult.current_project.destroy

        # Beam me up, scotty!
        redirect '/v1'
      end

      # get config
      get '/config/?' do
        erb :"admin/config"
      end
      
    end
  end
end
