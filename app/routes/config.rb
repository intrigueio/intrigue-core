class IntrigueApp < Sinatra::Base
  namespace '/v1/?' do

    # Get rid of all existing task runs
    get '/clear' do

      # Clear all task results
      keys = $intrigue_redis.keys "result:*"
      $intrigue_redis.del keys unless keys == []

      # Clear all scan results
      keys = $intrigue_redis.keys "scan_result:*"
      $intrigue_redis.del keys unless keys == []

      # Clear the default queue
      Sidekiq::Queue.new.clear

      # Beam me up, scotty!
      redirect '/v1'
    end

    # GET CONFIG
    get '/config' do
      erb :config
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
