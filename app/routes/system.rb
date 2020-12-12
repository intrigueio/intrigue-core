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
    get '/system/config/tasks/?' do
      @global_config = Intrigue::Core::System::Config
      erb :"system/task_config"
    end

    get '/system/config/handlers/?' do
      @global_config = Intrigue::Core::System::Config
      erb :"system/handler_config"
    end

    get "/system/entities" do
      @entities = Intrigue::EntityFactory.entity_types
      erb :"system/entities"
    end

    get "/system/tasks" do
      @tasks = Intrigue::TaskFactory.list
      erb :"system/tasks"
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
          puts "Setting config for #{handler_name} #{parameter_name}"
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

  #
  # status
  #
  get "/engine/?" do

    sidekiq_stats = Sidekiq::Stats.new
    project_listing = Intrigue::Core::Model::Project.all.map { |p|
        { :name => "#{p.name}", :entities => "#{p.entities.count}" } }

    output = {
      :version => IntrigueApp.version,
      :projects => project_listing,
      :tasks => {
        :processed => sidekiq_stats.processed,
        :failed => sidekiq_stats.failed,
        :queued => sidekiq_stats.queues
      }
    }

  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['OPTIONS','GET']

  content_type "application/json"
  output.to_json
  end



end
