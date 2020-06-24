class CoreApp < Sinatra::Base

  # Create a project!
  post '/api/v1/project' do

    content_type "application/json"
    add_standard_cors_headers
    
    halt_unless_authenticated(@params["key"])

    # When we create the project, we want to make sure no HTML is
    # stored, as we'll use this for display later on...
    project_name = get_json_payload[:project_name]
    new_project_name = CGI::escapeHTML(project_name)
    
    # don't allow empty project names
    if new_project_name.length == 0
      return wrap_core_api_response "Unable to create unnamed project: #{new_project_name}"
    end

    # create the project unless it exists
    if Intrigue::Core::Model::Project.first(:name => new_project_name)
      return wrap_core_api_response "Project exists!"
    else
      Intrigue::Core::Model::Project.create(:name => new_project_name, :created_at => Time.now.utc)
    end

    # woo success
    wrap_core_api_response "Project created!", { project: "#{new_project_name}"} 
  end


end