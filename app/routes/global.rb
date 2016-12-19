class IntrigueApp < Sinatra::Base

  namespace '/v1' do

    # Main Page
    get '/?' do
      erb :index
    end

    # Main Page
    get '/:project/?' do
      erb :index
    end

    get '/:project/admin/?' do
      erb :"admin/index"
    end

    # TODO - kill this
    # Get rid of all existing task runs
    get '/:project/admin/clear/?' do
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

      Intrigue::Model::TaskResult.scope_by_project(@project_name).destroy
      Intrigue::Model::Entity.scope_by_project(@project_name).destroy

      # Beam me up, scotty!
      redirect '/v1'
    end

    # get config
    get '/:project/admin/config/?' do
      @global_config = Intrigue::Config::GlobalConfig.new
      erb :"admin/config"
    end

  end
end
