require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  it "can be created" do
    project = Intrigue::Core::Model::Project.create(:name => "x")
    entity = Intrigue::Core::Model::Entity.create({
        :project => project,
        :type => "Intrigue::Core::Model::String",
        :name => "test"})

    expect(entity.name).to eq("test")
    expect(entity.project.name).to eq("x")
  end

  it "can be added to an entity group" do
    p = Intrigue::Core::Model::Project.create(:name => "testkasdfjh-#{rand(1000000)}")
    e = Intrigue::Core::Model::Entity.create(:project => p, :type => "Intrigue::Entity::String", :name => "z")
    g = Intrigue::Core::Model::AliasGroup.create(:project => p, :name=>"xyz"); g.save
    g.add_entity e;

    expect(g.name).to eq("xyz")
    #expect(g.entities.include?(e)).to be true
  end

end
end
end
