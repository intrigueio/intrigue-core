require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Logger" do

  it "creates a new logger" do

    project = Intrigue::Model::Project.create(:name => "TEST!")
    logger = Intrigue::Model::Logger.create( :project => project )

    logger.log("test")

    expect(logger).to exist
    expect(logger.full_log).to match(/.*\[\ \]\ test/)
  end

  it "is accessible through task_result" do

    project = Intrigue::Model::Project.create(:name => "TEST!")
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

    logger.log("test")
    expect(x.log).to match(/.*\[\ \]\ test/)
  end

end
end
end
