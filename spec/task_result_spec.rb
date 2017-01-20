require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "TaskResult" do

  it "can be created" do
    
    project = Intrigue::Model::Project.create(:name => "x")

    logger = Intrigue::Model::Logger.create( :project => project )

    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::DnsRecord",
        :name => "test"})

    x = Intrigue::Model::TaskResult.create({
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
