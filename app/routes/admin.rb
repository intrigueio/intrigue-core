class IntrigueApp < Sinatra::Base
  namespace '/v1' do

    namespace '/admin' do

      # Get rid of all existing task runs
      get '/clear' do

        to_clear = "task_result:*", "task_result_log:*","scan_result:*", "scan_result_log:*"

        to_clear.each do |k|
          keys = $intrigue_redis.keys k
          $intrigue_redis.del keys unless keys == []
        end

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
end
