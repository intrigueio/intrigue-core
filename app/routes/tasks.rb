class IntrigueApp < Sinatra::Base
  include Intrigue::Task::Helper
  namespace '/v1' do

    # Kick off a task
    get '/task/?' do
      # if we receive an entity_id or a task_result_id, instanciate the object
      if params["entity_id"]
        @entity = Intrigue::Model::Entity.current_project.all(:id => params["entity_id"]).first
      end

      # If we've been given a task result...
      if params["task_result_id"]
        @task_result = Intrigue::Model::TaskResult.current_project.all(:id => params["task_result_id"]).first
        @entity = @task_result.base_entity
      end

      # Always get us a list of tasks and names so we can display them
      @tasks = Intrigue::TaskFactory.list.map{|x| x.send(:new)}
      @task_names = @tasks.map{|t| t.metadata[:pretty_name]}.sort

      # get a list of task_results
      ### TODO - figure out how to filter this based on a nil association
      # http://stackoverflow.com/questions/7615752/datamapper-filter-records-by-association-count
      @task_results = Intrigue::Model::TaskResult.current_project.all(:scan_results => nil).page(params[:page])

      erb :'tasks/index'
    end

    # Helper to construct the request to the API when the application is used interactively
    post '/interactive/single/?' do

      # get the task name
      task_name = "#{@params["task"]}"
      entity_id = @params["entity_id"]
      current_project = Intrigue::Model::Project.current_project

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
        entity = Intrigue::Model::Entity.current_project.all(:id => entity_id).first
      else
        entity_type = @params["entity_type"]

        # TODO - make sure we catch DataMapper::SaveFailureError... why?

        # TODO - make sure we have a valid entity type first
        #   (check Intrigue::Model::Entity.descendants )

        klass = eval("Intrigue::Entity::#{entity_type}")
        entity = Intrigue::Model::Entity.create(
        { :type => klass,
          :name => "#{@params["attrib_name"]}",
          :details => entity_details,
          :project => current_project
        })
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
      task_result_id = start_task_run(current_project.id, nil, task_name, entity, options)
      task_result = Intrigue::Model::TaskResult.find(task_result_id).first

      entity.task_results << task_result
      entity.save

      redirect "/v1/task_results/#{task_result_id}"
    end


    # Show the results in a human readable format
    get '/task_results/:id/?' do

      task_result_id = params[:id].to_i

      # Get the task result from the database, and fail cleanly if it doesn't exist
      @result = Intrigue::Model::TaskResult.current_project.all(:id => task_result_id).first
      return "Unknown Task Result" unless @result

      # Assuming it's available, display it
      if @result
        @rerun_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}/v1/task/?task_result_id=#{@result.id}"
        @elapsed_time = "#{(@result.timestamp_end - @result.timestamp_start).to_i}" if @result.timestamp_end
      end

      erb :'tasks/task_result'
    end
  end
end
