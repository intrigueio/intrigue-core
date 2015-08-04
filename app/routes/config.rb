class IntrigueApp < Sinatra::Base
  namespace '/v1/?' do

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
