require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "ScanResult" do

  it "can be created" do

    project = Intrigue::Model::Project.create(:name => "x")

    logger = Intrigue::Model::Logger.create( :project => project )

    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::Host",
        :name => "test",
        :details => {} })

    x = Intrigue::Model::ScanResult.create({
      :project => project,
      :logger => logger,
      :base_entity => entity
    })

    expect(x).to exist
  end

  it "exports graph json" do

    project = Intrigue::Model::Project.create(:name => "x")

    logger = Intrigue::Model::Logger.create( :project => project )

    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::Host",
        :name => "test",
        :details => {} })

    x = Intrigue::Model::ScanResult.create({
      :project => project,
      :logger => logger,
      :base_entity => entity
    })

    expect x.export_graph_json =~ /nodes.*edges/

  end

end
end
end
