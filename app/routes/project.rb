class CoreApp < Sinatra::Base

    # Main Page
    get '/:project/?' do
      @projects = Intrigue::Core::Model::Project.order(:created_at).reverse.all
      erb :index
    end

    get '/:project/seeds?' do
      @project_name = params[:project]
      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
    erb :'project/seeds'
    end

    # configuration
    get '/:project/config?' do
      @project_name = params[:project]
      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
    erb :'project/config'
    end

    post '/:project/config?' do
      @project_name = params[:project]
      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      
      # set standard exceptions
      if @params["use_standard_exceptions"]
        @project.use_standard_exceptions = true
      end

      # set allowed namespaces
      @project.allowed_namespaces = @params["allowed_namespaces"].split("\n").map{|x|x.strip}.sort.uniq
      
      @project.save

    redirect "/#{@project_name}/config"
    end

    # Create a project!
    post '/project' do

      # When we create the project, we want to make sure no HTML is
      # stored, as we'll use this for display later on...
      new_project_name = CGI::escapeHTML(params[:project])
      
      if new_project_name.length == 0 
        session[:flash] = "Invalid project name!"
        redirect "/#{new_project_name}/start" # handy if we're in a browser
      end

      # create the project unless it exists
      unless Intrigue::Core::Model::Project.first(:name => new_project_name)
        Intrigue::Core::Model::Project.create(:name => new_project_name, :created_at => Time.now.utc)
      end

      redirect "/#{new_project_name}/start" # handy if we're in a browser
    end

    # save the config
    post '/project/delete' do

      # we have to collect the name bc we skip the before block
      @project_name = params[:project]
      project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # create the project unless it exists
      if project
        project.destroy

        # recreate the default project if we've removed
        if @project_name == "Default"
          Intrigue::Core::Model::Project.create(:name => "Default", :created_at => Time.now.utc)
        end
      end

      redirect '/' # handy if we're in a browser
    end

    get '/:project/start' do
      @project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # if we receive an entity_id or a task_result_id, instanciate the object
      if params["entity_id"]
        @entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => params["entity_id"])
      end

      # If we've been given a task result...
      if params["result_id"]
        @task_result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params["result_id"])
        @entity = @task_result.base_entity
      end

      @task_classes = Intrigue::TaskFactory.list
      erb :'start'
    end

    get '/:project/start/upload' do
      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      @task_classes = Intrigue::TaskFactory.list
      erb :'start'
    end

    # Run a specific handler on all scan results
    get '/:project/handle/:handler' do
      handler_name = params[:handler]

      project = Intrigue::Core::Model::Project.first(:name => @project_name)
      project.handle(handler_name)

    redirect "/#{@project_name}/start"
    end

    #### GRAPH ####

    # Project Graph
    get '/:project/graph.json/?' do
      content_type 'application/json'
      project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # Start a new generation
      unless project.graph_generation_in_progress
        Intrigue::Workers::GenerateGraphWorker.perform_async(project.id)
      end

    project.graph_json || "Currently generating..."
    end

    get '/:project/graph/meta.json/?' do
      content_type 'application/json'
      project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # Start a new generation
      unless project.graph_generation_in_progress
        Intrigue::Workers::GenerateMetaGraphWorker.perform_async(project.id)
      end

    project.graph_json || "Currently generating..."
    end


    # graph
    get '/:project/graph' do
      @json_uri = "#{request.url}.json"
      @graph_generated_at = Intrigue::Core::Model::Project.first(:name => @project_name).graph_generated_at
      erb :'graph'
    end

    # graph
    get '/:project/graph/generated_at' do
      "#{Intrigue::Core::Model::Project.first(:name => @project_name).graph_generated_at}"
    end

    # graph
    get '/:project/graph/meta' do
      @json_uri = "#{request.url}.json"
      @graph_generated_at = Intrigue::Core::Model::Project.first(:name => @project_name).graph_generated_at
      erb :'graph'
    end

    get '/:project/graph/reset' do
      p= Intrigue::Core::Model::Project.first(:name => @project_name)
      p.graph_generation_in_progress = false
      p.save
      redirect "/#{@project_name}/graph"
    end


    ### EXPORT
    get '/:project/export/json' do
      content_type 'application/json'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.json"

      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      @project.export_json
    end

    get '/:project/export/csv' do
      content_type 'application/csv'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.entities.csv"

      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      @project.export_entities_csv
    end

    get '/:project/export/applications/csv' do
      content_type 'application/csv'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.applications.csv"

      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      @project.export_applications_csv
    end

    get '/:project/export/issues/csv' do
      content_type 'application/csv'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.issues.csv"

      @project = Intrigue::Core::Model::Project.first(:name => @project_name)
      @project.export_issues_csv
    end

    # Show the results in a gexf format
    get '/:project/export/gexf/?' do
      content_type 'text/plain'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.gephi.gexf"

      @project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # Generate a list of entities and task runs to work through
      @entity_pairs = []
      @project.task_results.each do |task_result|
        task_result.entities.each do |entity|
          @entity_pairs << {:task_result => task_result, :entity => entity}
        end
      end

      erb :'gexf', :layout => false
    end

    get '/:project/export/graph_json' do
      content_type 'application/json'
      headers["Content-Disposition"] = "attachment;filename=#{@project_name}.graph.json"
      project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # Start a new generation
      unless project.graph_generation_in_progress
        Intrigue::Workers::GenerateGraphWorker.perform_async(project.id)
      end

      project.graph_json || "Currently generating..."
    end

end
