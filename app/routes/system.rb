class CoreApp < Sinatra::Base

    ###
    ### version
    ###
    get "/version.json" do
      { :version => CoreApp.version }.to_json
    end

    # Main Page
    get '/?' do
      @projects = Intrigue::Core::Model::Project.order(:created_at).reverse.all
      erb :index
    end

    ###                  ###
    ### System Config    ###
    ###                  ###
    post '/system/config' do

      Intrigue::Core::System::Config.config["credentials"]["username"] = "#{params["username"]}"
      Intrigue::Core::System::Config.config["credentials"]["password"] = "#{params["password"]}" unless "#{params["password"]}" =~ /^\*+$/

      # save and reload
      Intrigue::Core::System::Config.save

      redirect "/#{@project_name}"  # handy if we're in a browser
    end


    # get config
    get '/system/sidekiq/clear/?' do
      out = `redis-cli flushall`
      session[:flash] = "Sidekiq cache cleared: #{out}!"
      redirect "/system/config"
    end

    # get config
    get '/system/config/?' do
      @global_config = Intrigue::Core::System::Config
      erb :"system/system_config"
    end

    # get config
    get '/system/config/tasks/?' do
      @global_config = Intrigue::Core::System::Config
      erb :"system/task_config"
    end

    get '/system/config/handlers/?' do
      @global_config = Intrigue::Core::System::Config
      erb :"system/handler_config"
    end

    # save the config
    post '/system/config/tasks' do
      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      params.each do |k,v|
        # skip unless we already know about this config setting, helps us avoid
        # other parameters sent to this page (splat, project, etc)
        next unless Intrigue::Core::System::Config.config["intrigue_global_module_config"][k]
        Intrigue::Core::System::Config.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/
      end

      # save and reload
      Intrigue::Core::System::Config.save

      redirect "/system/config/tasks"  # handy if we're in a browser
    end

    # save the handler config
    post '/system/config/handlers' do
      # Update our config if one of the fields have been changed. Note that we use ***
      # as a way to mask out the full details in the view. If we have one that doesn't lead with ***
      # go ahead and update it
      params.each do |k,v|

        handler_name = k.split("____").first.strip
        parameter_name = k.split("____").last.strip

        # skip unless we already know about this config setting, helps us avoid
        # other parameters sent to this page (splat, project, etc)
        next unless Intrigue::Core::System::Config.config["intrigue_handlers"][handler_name]

        unless v =~ /^\*\*\*/
          Intrigue::Core::System::Config.config["intrigue_handlers"][handler_name][parameter_name] = v 
        end
      end

      # save and reload
      Intrigue::Core::System::Config.save

      redirect "/system/config/handlers"  # handy if we're in a browser
    end

  ###
  #### engine api
  ###


end
