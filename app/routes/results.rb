class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper
  namespace '/v1' do

    # Kick off a task
    get '/:project/results/?' do

      search_string = params["search_string"]

      # get a list of task_results
      @manual_results = Intrigue::Model::TaskResult.scope_by_project(@project_name).where(:autoscheduled => false).where(Sequel.ilike(:name, "%#{search_string}%"))
      @autoscheduled_results = Intrigue::Model::TaskResult.scope_by_project(@project_name).where(:autoscheduled => true).where(Sequel.ilike(:name, "%#{search_string}%"))
      erb :'results/index'
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/:project/interactive/single/?' do

      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]
      depth = @params["depth"].to_i
      current_project = Intrigue::Model::Project.first(:name => @project_name)
      entity_name = "#{@params["attrib_name"]}"

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

      # HACK! add the name to aliases, name detail no longer needed
      entity_details.delete("name")

      # Construct an entity from the data we have
      if entity_id
        entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:id => entity_id)
      else
        entity_type = @params["entity_type"]
        return unless entity_type

        entity = entity_exists?(current_project,entity_type,entity_name)

        unless entity

          # TODO - SECURITY - validate that it's a valid entity type before we eval
          klass = Intrigue::EntityManager.resolve_type entity_type

          entity = Intrigue::Model::Entity.create(
            { :name => entity_name,
              :type => klass,
              :details => entity_details,
              :project => current_project
            })

          Intrigue::EntityManager.enrich_entity entity

        end
      end

      raise "Unable to continue without entity: #{klass}##{entity_name}" unless entity

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
      task_result = start_task("task", current_project, nil, task_name, entity, depth, options)

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
