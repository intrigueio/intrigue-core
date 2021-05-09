class CoreApp < Sinatra::Base

    # Export All task results
    get '/:project/results.json/?' do
       session[:flash] = "Not implemented"
       redirect FRONT_PAGE
    end

    # Show the results in a CSV format
    get '/:project/results/:id.csv/?' do
      content_type 'text/plain'
      task_result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      task_result.export_csv
    end

    # Show the results in a CSV format
    get '/:project/results/:id.tsv/?' do
      content_type 'text/plain'
      task_result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/:project/results/:id.json/?' do
      content_type 'application/json'
      result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      result.export_json if result
    end

    get '/:project/results' do
      paginate_count = 100

      params[:search_string] == "" ? @search_string = nil : @search_string = "#{params[:search_string]}".strip
      params[:inverse] == "on" ? @inverse = true : @inverse = false
      params[:hide_enrichment] == "on" ? @hide_enrichment = true : @hide_enrichment = false
      params[:hide_autoscheduled] == "on" ? @hide_autoscheduled = true : @hide_autoscheduled = false
      params[:hide_cancelled] == "on" ? @hide_cancelled = true : @hide_cancelled = false
      params[:only_complete] == "on" ? @only_complete = true : @only_complete = false

      (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

      selected_results = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).reverse(:timestamp_start)

      if @search_string
        if @inverse
          selected_results = selected_results.exclude(Sequel.ilike(:name, "%#{@search_string}%"))
        else
          selected_results = selected_results.where(Sequel.ilike(:name, "%#{@search_string}%"))
        end
      end

      selected_results = selected_results.exclude(Sequel.ilike(:name, "%enrich%")) if @hide_enrichment
      selected_results = selected_results.exclude(:cancelled) if @hide_cancelled
      selected_results = selected_results.exclude(:autoscheduled) if @hide_autoscheduled
      selected_results = selected_results.exclude(:complete => false) if @only_complete

      # PAGINATE
      @result_count = selected_results.count
      @results = selected_results.extension(:pagination).paginate(@page,paginate_count)

      @calculated_url = "/#{h @project_name}/results?search_string=#{h @search_string}" +
        "&inverse=#{params[:inverse]}" +
        "&hide_enrichment=#{params[:hide_enrichment]}" +
        "&hide_autoscheduled=#{params[:hide_autoscheduled]}" +
        "&hide_cancelled=#{params[:hide_cancelled]}" +
        "&only_complete=#{params[:only_complete]}"

      erb :'results/index'
    end

    # Allow cancellation
    get '/:project/results/:id/cancel' do
      id = params[:id]
      if id == "all"
        Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).paged_each(:rows_per_fetch => 500) {|x| x.cancel! }
        redirect "/#{@project_name}/results"
      else
        Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id]).cancel!
        redirect "/#{@project_name}/results/#{params[:id]}"
      end
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/:project/interactive/single/?' do

      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]
      current_project = Intrigue::Core::Model::Project.first(:name => @project_name)
      entity_name = "#{@params["attrib_name"]}"
      auto_scope = true # manually created

      ### Handler definition, make sure we have a valid handler type
      if Intrigue::HandlerFactory.include? "#{@params["handler"]}"
        handlers = ["#{@params["handler"]}"]
      else
        handlers = []
      end

      ### Workflow definition, make sure we have a valid type
      workflow_name_string = "#{@params["workflow"]}".strip
      if wf = Intrigue::WorkflowFactory.create_workflow_by_name(workflow_name_string)
        workflow_name = wf.name
        workflow_depth = wf.depth || 5
      else # default to none
        workflow_name = nil
        workflow_depth = 1
      end

      auto_enrich = @params["auto_enrich"] == "on" ? true : false

      # Construct the attributes hash from the parameters. Loop through each of the
      # parameters looking for things that look like attributes, and add them to our
      # details hash
      entity_details = {}
      @params.each do |name,value|
        #puts "Looking at #{name} to see if it's an attribute"
        if name =~ /^attrib/
          entity_details["#{name.gsub("attrib_","")}"] = "#{value}"
        end
      end

      # Construct an entity from the data we have
      if entity_id
        entity = Intrigue::Core::Model::Entity.scope_by_project(@project_name).first(:id => entity_id)
      else
        entity_type = @params["entity_type"]
        return unless entity_type

        # create the first entity
        entity = Intrigue::EntityManager.create_first_entity(@project_name,entity_type,entity_name,entity_details)
      end

      unless entity
        session[:flash] = "Unable to create entity, check your parameters: #{entity_name} #{entity_type}!" +
        " For more help see the Entity Definitions under 'Help'!"
        redirect FRONT_PAGE
      end

      # Construct the options hash from the parameters
      options = []
      @params.each do |name,value|
        if name =~ /^option/

          clean_option_name = name.gsub("option_","")

          # handle nil
          clean_option_value = value == "null" ? nil : value

          # handle bool
          if ["false","true"].include? clean_option_value
            clean_option_value = clean_option_value.to_bool
          end

          options << {
            "name" => "#{clean_option_name}",
            "value" => clean_option_value
          }

        end
      end

      # Start the task run!
      task_result = start_task("task", current_project, nil, task_name, entity,
                                workflow_depth, options, handlers, workflow_name,
                                auto_enrich, auto_scope)

      entity.task_results << task_result
      entity.save

      # Manually starting enrichment here
      if auto_enrich && !(task_name =~ /^enrich/)
        entity.enrich(task_result)
      end

      redirect "/#{@project_name}/results/#{task_result.id}"
    end

    post '/:project/interactive/upload' do
      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]
      entity_name = "#{@params["attrib_name"]}".strip
      file_format = "#{@params["file_format"]}".strip

      # first check that our file is sane
      file_type = @params["entity_file"]["type"]
      puts "Got file of type: #{file_type}"

      # barf if we got a bad file
      unless file_type =~ /^text/ || file_type == "application/octet-stream"
        session[:flash] = "Bad file data, ensure we're a text file and valid format: #{file_type}"
        redirect FRONT_PAGE
      end

      # get the file
      entity_file = @params["entity_file"]["tempfile"]

      ###
      ### Standard file type (entity list)
      ###

      # handle file if we got it
      if file_format == "entity_list"
        entities = core_csv_to_entities(entity_file)
      ### Intrigue.io Bulk FP
      elsif file_format == "intrigueio_fingerprint_csv"
        entities = intrigueio_csv_to_entities(entity_file)
      ### Alienvault OTX (CSV)
      elsif file_format == "otx_csv"
        entities = alienvault_otx_csv_to_entities(entity_file)
      ### BinaryEdge (JSON)
      elsif file_format == "binary_edge_jsonl"
        entities = binary_edge_jsonl_to_entities(entity_file)
      ### Shodan.io (CSV)
      elsif file_format == "shodan_csv"
        entities = shodan_csv_to_entities(filename)
      else
        session[:flash] = "Unkown File Format #{file_format}, failing"
        redirect FRONT_PAGE
      end

      ### Handler definition, make sure we have a valid handler type
      if Intrigue::HandlerFactory.include? "#{@params["handler"]}"
        handlers = ["#{@params["handler"]}"]
      else
        handlers = []
      end

      ### Workflow definition, make sure we have a valid type
      workflow_name_string = "#{@params["workflow"]}".strip
      if wf = Intrigue::WorkflowFactory.create_workflow_by_name(workflow_name_string)
        workflow_name = wf.name
        workflow_depth = wf.default_depth
      else
        workflow_name = nil
        workflow_depth = 1
      end

      auto_enrich = @params["auto_enrich"] == "on" ? true : false
      auto_scope = true # manually created

      # set our project (default)
      current_project = Intrigue::Core::Model::Project.first(:name => @project_name)

      # for each entity in thefile

      entities.each do |e|
        entity_type = e[:entity_type]
        entity_name = e[:entity_name]

        ###
        ### If collection was set, overried the project on a per-entity basis
        ###
        if e[:collection]
          project = e[:collection]
          current_project = Intrigue::Core::Model::Project.update_or_create(:name => project)
        end

        # create the first entity with empty details
        #next unless Intrigue::EntityFactory.entity_types.include?(entity_type)
        entity = Intrigue::EntityManager.create_first_entity(current_project.name ,entity_type,entity_name,{})

        # skip anything we can't parse, silently fail today :[
        unless entity
          next
        end

        # Start the task run!
        task_result = start_task("task", current_project, nil, task_name, entity,
                  workflow_depth, nil, handlers, workflow_name, auto_enrich, auto_scope)

        entity.task_results << task_result
        entity.save

        # manually start enrichment for the first entity
        if auto_enrich && !(task_name =~ /^enrich/)
          task_result.log "User-created entity, manually creating and enriching!"
          entity.enrich(task_result)
        end

      end

      redirect "/#{@project_name}/results"
    end

    # Show the results in a human readable format
    get '/:project/results/:id/?' do
      task_result_id = params[:id].to_i

      # Get the task result from the database, and fail cleanly if it doesn't exist
      @result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => task_result_id)
      return "Unknown Task Result" unless @result

      # Assuming it's available, display it
      if @result
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/#{h @project_name}/start/task?result_id=#{@result.id}"
        @elapsed_time = "#{(@result.timestamp_end - @result.timestamp_start).to_i}" if @result.timestamp_end
      end

      erb :'results/detail'
    end


    ###                          ###
    ### Per-Project Task Results ###
    ###                          ###

    # Create a task result from a json request
    # What we receive should look like this:
    #
    #payload = {
    #  "project_name" => project_name,
    #  "handlers" => []
    #  "task" => "task_name",
    #  "workflow_name" => "intrigueio_test_workflow",
    #  "entity" => { "type" : "Domain", "name" : "test" },
    #  "options" => [],
    #  "auto_enrich" => false
    #}.to_json
    post '/:project/results/?' do

      # Parse the incoming request
      payload = JSON.parse(request.body.read) if (request.content_type == "application/json" && request.body)

      ### don't take any shit
      raise InvalidEntityError, "Empty Payload?" unless payload

      # Construct an entity from the entity_hash provided
      type_string = payload["entity"]["type"]
      name = payload["entity"]["name"]

      resolved_type = Intrigue::EntityManager.resolve_type_from_string type_string

      attributes = payload["entity"].merge(
        "type" => resolved_type.to_s,
        "name" => "#{name}"
      )

      ### Workflow definition, make sure we have a valid type
      workflow_name_string = "#{@params["workflow"]}".strip
      if wf = Intrigue::Core::Model::Workflow.first(:name => "#{@params["workflow_name"]}")
        workflow_name = wf.name
        workflow_depth = wf.default_depth
      else
        workflow_name = nil
        workflow_depth = 1
      end


      # Get the details from the payload
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]
      auto_enrich = "#{payload["auto_enrich"]}".to_bool
      auto_scope = true # manually created

      # create the first entity
      entity = Intrigue::EntityManager.create_first_entity(@project_name,type_string,name,{})

      # create the project if it doesn't exist
      project = Intrigue::Core::Model::Project.first(:name => @project_name)
      project = Intrigue::Core::Model::Project.create(:name => @project_name) unless project

      # Start the task_run
      task_result = start_task("task", project, nil, task_name, entity, workflow_depth,
                                  options, handlers, workflow_name, auto_enrich, auto_scope)

      # manually start enrichment, since we've already created the entity above, it won't auto-enrich ^
      if auto_enrich && !(task_name =~ /^enrich/)
        task_result.log "User-created entity, manually creating and enriching!"
        entity.enrich(task_result)
      end

      #status 200 if task_result

    # must be a string otherwise it can be interpreted as a status code
    {"result_id" => task_result.id}.to_json
    end


    # Determine if the task run is complete
    get '/:project/results/:id/complete/?' do
      # Get the task result and return unless it's false
      x = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return false unless x

      # if we got it, and it's complete, return true
      return "true" if x.complete

    # Otherwise, not ready yet, return false
    false
    end

    # Get the task log
    get '/:project/results/:id/log/?' do
      content_type 'application/json'
      result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless result

      {:data => result.get_log}.to_json
    end

    ### Handling

    # Run a specific handler on a specific task result
    get '/:project/results/:id/handle/:handler' do
      handler_name = params[:handler]
      result_id = params[:id].to_i

      # Get the result from the database, and fail cleanly if it doesn't exist
      result = Intrigue::Core::Model::TaskResult.scope_by_project(@project_name).first(:id => result_id)

      # run the handler(s) we set up
      result.handle(handler_name)

    redirect "/#{@project_name}/results/#{result_id}"
    end

end
