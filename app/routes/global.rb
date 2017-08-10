class IntrigueApp < Sinatra::Base

    ###
    ### version
    ###
    get "/version.json" do
      { :version => IntrigueApp.version }.to_json
    end

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


    ###                  ###
    ### System Config    ###
    ###                  ###

    post '/:project/config/system' do
      global_config = Intrigue::Config::GlobalConfig.new
      global_config.config["credentials"]["username"] = "#{params["username"]}"
      global_config.config["credentials"]["password"] = "#{params["password"]}"
      global_config.save
      redirect "/#{@project_name}"  # handy if we're in a browser
    end

    # save the config
    post '/:project/config/task' do
      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      global_config = Intrigue::Config::GlobalConfig.new
      params.each do |k,v|
        # skip unless we already know about this config setting, helps us avoid
        # other parameters sent to this page (splat, project, etc)
        next unless global_config.config["intrigue_global_module_config"][k]
        global_config.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/
      end
      global_config.save

      redirect "/#{@project_name}"  # handy if we're in a browser
    end

    # save the config
    post '/:project/config/handler' do
      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      begin
        handler_hash = JSON.parse(params["handler_json"])
        global_config = Intrigue::Config::GlobalConfig.new
        global_config.config["intrigue_handlers"] = handler_hash
        global_config.save
      rescue JSON::ParserError => e
        return "Error! #{e}"
      end

      redirect "/#{@project_name}"  # handy if we're in a browser
    end


    # get config
    get '/:project/admin/config/?' do
      @global_config = Intrigue::Config::GlobalConfig.new
      erb :"admin/config"
    end

end
