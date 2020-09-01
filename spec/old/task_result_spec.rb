require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "TaskResult" do

  it "can be created" do

    project = Intrigue::Core::Model::Project.create(:name => "x")

    logger = Intrigue::Core::Model::Logger.create( :project => project )

    entity = Intrigue::Core::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Core::Model::Host",
        :name => "test"})

    x = Intrigue::Core::Model::TaskResult.create({
      :project => project,
      :logger => logger,
      :base_entity => entity,
      :task_name => "example"
    })

    expect(x).to exist
    expect(x.logger).to exist
    expect(x.project.name).to eq("x")
    expect(x.task.class.metadata[:name]).to match "example"
  end

end
end
end
