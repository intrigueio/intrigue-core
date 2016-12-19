require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "TaskResult" do

  it "a task result should allow us to get an instance of the underlying task" do
    x = Intrigue::Model::TaskResult.create({
      :project_id => Intrigue::Model::Project.first.id,
      :logger_id => Intrigue::Model::Logger.create.id,
      :task_name => "example"
    })
    expect(x.task.class.metadata[:name]).to match "example"
  end

end
end
end
