require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Logger" do

  it "can be created" do

    project = Intrigue::Core::Model::Project.create(:name => "x")
    logger = Intrigue::Core::Model::Logger.create( :project => project )

    logger.log("test")

    expect(logger).to exist
    expect(logger.full_log).to match(/.*\[\ \]\ test/)
  end

  it "is accessible through task_result" do

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

    logger.log("test")
    expect(x.log).to match(/.*\[\ \]\ test/)
  end

end
end
end
