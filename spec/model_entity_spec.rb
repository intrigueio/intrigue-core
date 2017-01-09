require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  it "creates a new entity" do

    project = Intrigue::Model::Project.create(:name => "TEST!")

    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::DnsRecord",
        :name => "test"})

    entity = Intrigue::Model::Entity.last

    #expect(first_entity.id).to eq(1)
    expect(entity.name).to eq("test")
    expect(entity.project.name).to eq("TEST!")
  end

end
end
end
