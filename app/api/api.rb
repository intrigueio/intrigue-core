class IntrigueApp < Sinatra::Base

  # Export All Tasks
  get "/api/v1/tasks" do 
    content_type 'application/json'
    JSON.pretty_generate(Intrigue::TaskFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] })
  end

end