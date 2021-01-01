class CoreApp < Sinatra::Base
  get "/help/entities" do
    @entities = Intrigue::EntityFactory.entity_types
    erb :"system/entities"
  end

  get "/help/issues" do
    @issues = Intrigue::Issue::IssueFactory.issues
    erb :"system/issues"
  end

  get "/help/tasks" do
    @tasks = Intrigue::TaskFactory.list
    erb :"system/tasks"
  end
end