class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper

    # Export All task results
    get '/:project/results.json/?' do
       raise "Not implemented"
    end

    # Show the results in a CSV format
    get '/:project/results/:id.csv/?' do
      content_type 'text/plain'
      task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      task_result.export_csv
    end

    # Show the results in a CSV format
    get '/:project/results/:id.tsv/?' do
      content_type 'text/plain'
      task_result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      task_result.export_tsv
    end

    # Show the results in a JSON format
    get '/:project/results/:id.json/?' do
      content_type 'application/json'
      result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      result.export_json if result
    end


    get '/:project/results' do
      paginate_count = 100
      @exclude_enrichment = true

      params[:search_string] == "" ? @search_string = nil : @search_string = "#{params[:search_string]}"
      params[:inverse] == "on" ? @inverse = true : @inverse = false
      params[:hide_enrichment] == "on" ? @hide_enrichment = true : @hide_enrichment = false
      params[:hide_autoscheduled] == "on" ? @hide_autoscheduled = true : @hide_autoscheduled = false
      params[:hide_cancelled] == "on" ? @hide_cancelled = true : @hide_cancelled = false
      params[:only_complete] == "on" ? @only_complete = true : @only_complete = false

      (params[:page] != "" && params[:page].to_i > 0) ? @page = params[:page].to_i : @page = 1

      selected_results = Intrigue::Model::TaskResult.scope_by_project(@project_name).reverse(:timestamp_start)

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

      erb :'results/index'
    end

=begin
    # Kick off a task
    get '/:project/results/?' do
      search_string = params["search_string"]
      # get a list of task_results
      erb :'results/index'
    end
=end

    # Allow cancellation
    get '/:project/results/:id/cancel' do
      id = params[:id]
      if id == "all"
        Intrigue::Model::TaskResult.scope_by_project(@project_name).each {|x| x.cancel! }
        redirect "/#{@project_name}/results"
      else
        Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id]).cancel!
        redirect "/#{@project_name}/results/#{params[:id]}"
      end
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/:project/interactive/single/?' do

      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]
      depth = @params["depth"].to_i
      current_project = Intrigue::Model::Project.first(:name => @project_name)
      entity_name = "#{@params["attrib_name"]}"

      ### Handler definition, make sure we have a valid handler type
      if Intrigue::HandlerFactory.include? "#{@params["handler"]}"
        handlers = ["#{@params["handler"]}"]
      else
        handlers = []
      end

      ### Strategy definition, make sure we have a valid type
      if Intrigue::StrategyFactory.has_strategy? "#{@params["strategy"]}"
        strategy_name = "#{@params["strategy"]}"
      else
        strategy_name = "discovery"
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
        entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => entity_id)
      else
        entity_type = @params["entity_type"]
        return unless entity_type

        # create the first entity
        entity = Intrigue::EntityManager.create_first_entity(@project_name,
                                          entity_type,entity_name,entity_details, auto_enrich, depth)
      end

      unless entity
        raise "Unable to create entity, check your parameters: #{entity_name} #{entity_type}!"
      end

      # Construct the options hash from the parameters
      options = []
      @params.each do |name,value|
        if name =~ /^option/
          options << {
                      "name" => "#{name.gsub("option_","")}",
                      "value" => "#{value}"
                      }
        end
      end

      # Start the task run!
      task_result = start_task("task", current_project, nil, task_name, entity,
                                depth, options, handlers, strategy_name, auto_enrich)

      entity.task_results << task_result
      entity.save

      redirect "/#{@project_name}/results/#{task_result.id}"
    end


    # Show the results in a human readable format
    get '/:project/results/:id/?' do
      task_result_id = params[:id].to_i

      # Get the task result from the database, and fail cleanly if it doesn't exist
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => task_result_id)
      return "Unknown Task Result" unless @result

      # Assuming it's available, display it
      if @result
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/#{@project_name}/start?result_id=#{@result.id}"
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
    #  "task" => task_name,
    #  "entity" => entity_hash,
    #  "options" => options_list,
    #  "auto_enrich" => false
    #}.to_json
    post '/:project/results/?' do

      # Parse the incoming request
      payload = JSON.parse(request.body.read) if (request.content_type == "application/json" && request.body)
      puts "Got Payload #{payload}"

      ### don't take any shit
      return "No payload!" unless payload

      # Construct an entity from the entity_hash provided
      type_string = payload["entity"]["type"]
      name = payload["entity"]["name"]

      # Collect the depth (which can kick off a recursive "scan", but default to a single)
      depth = payload["depth"] || 1

      resolved_type = Intrigue::EntityManager.resolve_type_from_string type_string

      attributes = payload["entity"].merge(
        "type" => resolved_type.to_s,
        "name" => "#{name}"
      )

      # get the details from the payload
      task_name = payload["task"]
      options = payload["options"]
      handlers = payload["handlers"]
      strategy_name = payload["strategy_name"]

      # default to false for enrichment
      if payload["auto_enrich"]
        auto_enrich = "#{payload["auto_enrich"]}".to_bool
      else
        auto_enrich = false
      end

      # create the first entity
      entity = Intrigue::EntityManager.create_first_entity(@project_name,type_string,name,{}, auto_enrich, depth)

      # create the project if it doesn't exist
      project = Intrigue::Model::Project.first(:name => @project_name)
      project = Intrigue::Model::Project.create(:name => @project_name) unless project

      # Start the task_run
      task_result = start_task("task", project, nil, task_name, entity, depth,
                                  options, handlers, strategy_name, auto_enrich)
      status 200 if task_result

    # must be a string otherwise it can be interpreted as a status code
    {"result_id" => task_result.id}.to_json
    end


    # Determine if the task run is complete
    get '/:project/results/:id/complete/?' do
      # Get the task result and return unless it's false
      x = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return false unless x

      # if we got it, and it's complete, return true
      return "true" if x.complete

    # Otherwise, not ready yet, return false
    false
    end

    # Get the task log
    get '/:project/results/:id/log/?' do
      content_type 'application/json'
      result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id])
      return unless result

      {:data => result.get_log}.to_json
    end

    ### Handling

    # Run a specific handler on a specific task result
    get '/:project/results/:id/handle/:handler' do
      handler_name = params[:handler]
      result_id = params[:id].to_i

      # Get the result from the database, and fail cleanly if it doesn't exist
      result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => result_id)

      # run the handler(s) we set up
      result.handle(handler_name)

    redirect "/#{@project_name}/results/#{result_id}"
    end

end
