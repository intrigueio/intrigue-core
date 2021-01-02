class CoreApp < Sinatra::Base
  get "/help/entities" do
    @entities = Intrigue::EntityFactory.entity_types
    erb :"help/entities"
  end

  get "/help/issues" do
    @issues = Intrigue::Issue::IssueFactory.issues
    erb :"help/issues"
  end

  get "/help/tasks" do
    @tasks = Intrigue::TaskFactory.list
    erb :"help/tasks"
  end
end