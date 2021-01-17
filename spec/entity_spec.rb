require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Entity" do

  #https://relishapp.com/rspec/rspec-core/v/2-0/docs/hooks/before-and-after-hooks
  before(:each) do 
    
    # global entities
    @ge1 = Intrigue::Core::Model::GlobalEntity.update_or_create type: "Domain", name: "test.com", namespace: "AAA"
    @ge2 = Intrigue::Core::Model::GlobalEntity.update_or_create type: "Domain", name: "alreadyclaimed.com", namespace: "BBB"
    
    # project 
    @p = Intrigue::Core::Model::Project.update_or_create(name: "test")
    
    # entity 
    typex = "Intrigue::Entity::Domain"
    namex = "test.com"
    Intrigue::Core::Model::Entity.update_or_create(project: @p, type: typex, name: namex)
    @e = Intrigue::Core::Model::Entity.first type: typex, name: namex   

    # alias groups 
    @ag = Intrigue::Core::Model::AliasGroup.update_or_create(project_id: @p.id, name: "xyz");

  end

  after(:each) do  
    @ge1.delete
    @ge2.delete
    @p.delete!
  end

  it "can be created" do
    expect(@e.project.name).to eq("AAA")
    expect(@e.name).to eq("test.com")
  end

  it "can be added to an entity group" do
    @ag.add_entity @e;
    expect(@ag.name).to eq("xyz")
    # TODO... more verification needed here 
  end

  it "will find test.com traversable" do
    expect(@p.traversable_entity?(@e)).to eq(true)
  end 

  it "will find alreadyclaimed.com not traversable" do
    
    # create the entity 
    t = "Intrigue::Entity::Domain"
    s = "alreadyclaimed.com"
    e = Intrigue::Core::Model::Entity.new({
      project_id: @p.id, 
      type: t, 
      name: s
    })
    e.save

    @p.allowed_namespaces = ["invalid"]
    @p.save

    e = Intrigue::Core::Model::Entity.first type: t, name: s    

    expect(@p.allow_list_entity?(e)).to eq(false)
    expect(@p.deny_list_entity?(e)).to eq(true)
    expect(@p.traversable_entity?(e)).to eq(false)
  end

  #it "should find google out of scope" do
  #  e = Intrigue::Core::Model::Entity.create(
  #    project_id: @p.id, type: "Domain", name: "google.com")
  #end

end
end
end
