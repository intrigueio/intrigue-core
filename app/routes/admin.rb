class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    namespace '/admin' do

      get '/?' do
        erb :"admin/index"
      end

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

        # Beam me up, scotty!
        redirect '/v1'
      end

      # GET CONFIG
      get '/config/?' do
        erb :"admin/config"
      end

      # SAVE CONFIG
      post '/config' do

        params.each {|k,v| $intrigue_config[k]["value"]=v}

        # Write our config back to the file
        File.open("#{$intrigue_basedir}/config/config.json", 'w') do |f|
          f.write JSON.pretty_generate $intrigue_config
        end

        # Re-read the config
        $intrigue_config = JSON.parse File.read("#{$intrigue_basedir}/config/config.json")

        redirect '/'
      end
    end
  end
end
