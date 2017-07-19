class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper
  namespace '/v1' do

    get '/:project/results' do
      paginate_count = 100
      @exclude_enrichment = true

      params[:search_string] == "" ? @search_string = nil : @search_string = "#{params[:search_string]}"
      params[:inverse] == "on" ? @inverse = true : @inverse = false
      params[:hide_enrichment] == "on" ? @hide_enrichment = true : @hide_enrichment = false
      params[:hide_autoscheduled] == "on" ? @hide_autoscheduled = true : @hide_autoscheduled = false
      params[:hide_cancelled] == "on" ? @hide_cancelled = true : @hide_cancelled = false
      params[:hide_complete] == "on" ? @hide_complete = true : @hide_complete = false

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
      selected_results = selected_results.exclude(:complete) if @hide_complete


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
      else
        Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => params[:id]).cancel!
      end
      redirect "/v1/#{@project_name}/results"
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
                                          entity_type,entity_name,entity_details)
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

      redirect "/v1/#{@project_name}/results/#{task_result.id}"
    end


    # Show the results in a human readable format
    get '/:project/results/:id/?' do
      task_result_id = params[:id].to_i

      # Get the task result from the database, and fail cleanly if it doesn't exist
      @result = Intrigue::Model::TaskResult.scope_by_project(@project_name).first(:id => task_result_id)
      return "Unknown Task Result" unless @result

      # Assuming it's available, display it
      if @result
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1/#{@project_name}/start?result_id=#{@result.id}"
        @elapsed_time = "#{(@result.timestamp_end - @result.timestamp_start).to_i}" if @result.timestamp_end
      end

      erb :'results/detail'
    end

  end
end
