class IntrigueApp < Sinatra::Base
  namespace '/v1' do
    namespace '/admin' do

      get '/?' do
        erb :"admin/index"
      end

=begin
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

        Intrigue::Model::Entity.all.destroy
        Intrigue::Model::TaskResult.all.destroy
        Intrigue::Model::ScanResult.all.destroy

        # Beam me up, scotty!
        redirect '/v1'
      end
=end
      # get config
      get '/config/?' do
        erb :"admin/config"
      end

      # save the config
      post '/config' do

        # Update our config if one of the fields have been changed. Note that we use ***
        # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
        # go ahead and update it
        params.each {|k,v| $intrigue_config.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/ }
        $intrigue_config.save

        redirect '/v1/admin/config'
      end
    end
  end
end
