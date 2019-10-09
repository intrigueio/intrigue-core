class IntrigueApp < Sinatra::Base

    ###
    ### version
    ###
    get "/version.json" do
      { :version => IntrigueApp.version }.to_json
    end

    # Main Page
    get '/?' do
      @projects = Intrigue::Model::Project.order(:created_at).reverse.all
      erb :index
    end

    ###                  ###
    ### System Config    ###
    ###                  ###
    post '/system/config' do
      
      Intrigue::Config::GlobalConfig.config["credentials"]["username"] = "#{params["username"]}"
      Intrigue::Config::GlobalConfig.config["credentials"]["password"] = "#{params["password"]}"

      # save and reload
      Intrigue::Config::GlobalConfig.save


      redirect "/#{@project_name}"  # handy if we're in a browser
    end

    # get config
    get '/system/config/?' do
      @global_config = Intrigue::Config::GlobalConfig
      erb :"system/config"
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
        next unless Intrigue::Config::GlobalConfig.config["intrigue_global_module_config"][k]
        Intrigue::Config::GlobalConfig.config["intrigue_global_module_config"][k]["value"] = v unless v =~ /^\*\*\*/
      end

      # save and reload 
      Intrigue::Config::GlobalConfig.save

      redirect "/system/config"  # handy if we're in a browser
    end

  ###  
  #### engine api 
  ###

  #
  # status
  #
  get "/engine/?" do

    sidekiq_stats = Sidekiq::Stats.new
    project_listing = Intrigue::Model::Project.all.map { |p|
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
