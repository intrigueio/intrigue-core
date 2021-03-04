class CoreApp < Sinatra::Base

  def wrapped_api_response(error, result=nil)
    success = error.nil?
  {success: success, error: error, result: result}.to_json
  end

  # Export All Entity Types
  get "/api/v1/entities" do
    content_type 'application/json'
    
    entity_metadata = Intrigue::EntityFactory.entity_types.map{ |e| e.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, entity_metadata)
  end

  # Export All Task Metadata
  get "/api/v1/tasks" do
    content_type 'application/json'

    tasks_metadata = Intrigue::TaskFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, tasks_metadata)
  end

  # Export All Task Metadata
  get "/api/v1/machines" do
    content_type 'application/json'

    machine_metadata = Intrigue::MachineFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, machine_metadata)
  end


  # Export All Task Metadata
  get "/api/v1/handlers" do
    content_type 'application/json'
    handler_metadata = Intrigue::HandlerFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, handler_metadata)
  end

  # Export a specific Task's metadataa
  get "/api/v1/tasks/:task_name" do
    content_type 'application/json'

    task_name = params[:task_name]

    # Attempg to get the task
    task = Intrigue::TaskFactory.list.select{|t| t.metadata[:name] == task_name }.first
    task_metadata = task.metadata if task

    unless task_metadata
      status 400
      return wrapped_api_response("unable to find task with that name")
    end

    wrapped_api_response(nil, task_metadata)
  end

end
