class CoreApp < Sinatra::Base

  # System status
  get "/api/v1/health/?" do

    content_type 'application/json'

    halt_unless_authenticated!

    sidekiq_stats = Sidekiq::Stats.new
    project_listing = Intrigue::Core::Model::Project.all.map { |p|
        { :name => "#{p.name}", :entities => "#{p.entities.count}" } }

    output = {
      :version => CoreApp.version,
      :projects => project_listing,
      :tasks => {
        :processed => sidekiq_stats.processed,
        :failed => sidekiq_stats.failed,
        :queued => sidekiq_stats.queues
      }
    }

    output[:memory] = `free -h`
    output[:processes] = `god status`
    output[:disk] = `df -h`


  wrapped_api_response(nil, output)
  end


  # Export All Entity Types
  get "/api/v1/entities" do
    content_type 'application/json'

    halt_unless_authenticated!

    entity_metadata = Intrigue::EntityFactory.entity_types.map{ |e| e.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, entity_metadata)
  end

  # Export All Task Metadata
  get "/api/v1/tasks" do
    content_type 'application/json'

    halt_unless_authenticated!

    tasks_metadata = Intrigue::TaskFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, tasks_metadata)
  end

  # Export All Workflows
  get "/api/v1/workflows" do
    content_type 'application/json'

    halt_unless_authenticated!

    workflow_metadata = Intrigue::Core::Model::Workflow.all.map{ |t| t.to_hash }.sort_by{|m| m[:name] }

  wrapped_api_response(nil, workflow_metadata)
  end

  # Export All Handlers
  get "/api/v1/handlers" do
    content_type 'application/json'

    halt_unless_authenticated!

    handler_metadata = Intrigue::HandlerFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }
  wrapped_api_response(nil, handler_metadata)
  end

  # Export a specific Task's metadataa
  get "/api/v1/tasks/:task_name" do
    content_type 'application/json'

    halt_unless_authenticated!

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
