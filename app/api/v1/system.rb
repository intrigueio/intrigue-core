class IntrigueApp < Sinatra::Base

  # Export All Task Metadata
  get "/api/v1/tasks" do 
    content_type 'application/json'
    Intrigue::TaskFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }.to_json
  end

  # Export All Entity Types
  get "/api/v1/entities" do 
    content_type 'application/json'
    Intrigue::EntityFactory.entity_types.map{ |e| e.metadata }.sort_by{|m| m[:name] }.to_json
  end

  # Export a specific Task's metadataa
  #get "/api/v1/tasks/:task_name" do 
  #  content_type 'application/json'
  #  task_name = params[:splat][0..-1].join('/')
  #  Intrigue::TaskFactory.list.select{|t| t.metadata[:name] == task_name }.first.metadata.to_json
  #end 

end