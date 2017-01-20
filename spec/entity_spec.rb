require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  it "can be created" do
    project = Intrigue::Model::Project.create(:name => "x")
    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::DnsRecord",
        :name => "test"})

    expect(entity.name).to eq("test")
    expect(entity.project.name).to eq("x")
  end

end
end
end
