require 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  it "can be created" do
    project = Intrigue::Model::Project.create(:name => "x")
    entity = Intrigue::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Model::Host",
        :name => "test"})

    expect(entity.name).to eq("test")
    expect(entity.project.name).to eq("x")
  end

  it "can be added to an entity group" do
    p = Intrigue::Model::Project.create(:name => "testkasdfjh-#{rand(1000000)}")
    e = Intrigue::Model::Entity.create(:project => p, :name => "z")
    g = Intrigue::Model::AliasGroup.create(:project => p, :name=>"whatever"); g.save
    g.add_entity e;
    expect(g.name).to eq("whatever")
    expect(g.entities).to_include("z")
  end

end
end
end
