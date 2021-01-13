require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  #https://relishapp.com/rspec/rspec-core/v/2-0/docs/hooks/before-and-after-hooks
  before(:all) do 
    Intrigue::Core::Model::GlobalEntity.create type: "Intrigue::Entity::Domain", name: "test.com", namespace: "test"
    @p = Intrigue::Core::Model::Project.create :name => "test"
  end

  after(:all) do 
    Intrigue::Core::Model::GlobalEntity.truncate
    Intrigue::Core::Model::Project.truncate 
  end

  it "can be created" do
    entity = Intrigue::Core::Model::Entity.create({
        :project => @p,
        :type => "Intrigue::Core::Model::String",
        :name => "test"})

    expect(entity.name).to eq("test")
    expect(entity.project.name).to eq("test")
  end

  it "can be added to an entity group" do
    e = Intrigue::Core::Model::Entity.create(:project => @p, :type => "Intrigue::Entity::String", :name => "z")
    g = Intrigue::Core::Model::AliasGroup.create(:project => @p, :name=>"xyz"); g.save
    g.add_entity e;

    expect(g.name).to eq("xyz")
    #expect(g.entities.include?(e)).to be true
  end


  it "will find test.com traversable" do
    e = Intrigue::Core::Model::Entity.create(project: @p, type: "Intrigue::Entity::Domain", name: "test.com")
    @p.traversable_entity?(e.type_string, e.name)
  end 




end
end
end
