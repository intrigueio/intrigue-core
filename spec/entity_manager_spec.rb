require_relative 'spec_helper'

describe "Intrigue" do
describe "EntityManager" do

  #https://relishapp.com/rspec/rspec-core/v/2-0/docs/hooks/before-and-after-hooks
#https://relishapp.com/rspec/rspec-core/v/2-0/docs/hooks/before-and-after-hooks
before(:each) do
  # project 
  @p = Intrigue::Core::Model::Project.update_or_create(name: "test")
end

after(:each) do
  @p.delete!
end

  it "should successfully create a well-formed new entity"  do 
    e = Intrigue::EntityManager.create_first_entity "test", "Domain", "test.com", {}
    expect(e).to be_kind_of(Intrigue::Entity::Domain)
  end

  it "should fail to successfully create an ill-formed new entity"  do 
    e = Intrigue::EntityManager.create_first_entity "test", "Domain", "!!!!bad!.com", {}
    expect(e).to be(nil)
  end

=begin
  it "should successfully merge an entity"  do 

    # create a logger 
    l = Intrigue::Core::Model::Logger.create( project_id: @p.id)
    
    # now create the base entity 
    e1 = Intrigue::EntityManager.create_first_entity @p.name, "Domain", "test.com", {"foo" => "bar"}

    t = Intrigue::Core::Model::TaskResult.create(
      name: "test_task", project_id: @p.id, logger_id: l.id, base_entity_id: e1.id )

    e2 = Intrigue::EntityManager.create_or_merge_entity t.id, "Domain", "test.com", {"baz" => "bar"}

    expect(e2.details.to_h).to be_kind_of(Hash)
    expect(e2.details).to have_key("source_task_list")
    expect(e2.details).to have_key("foo")
    expect(e2.details).to have_key("baz")
    
  end
=end

  #it "should successfully create a second entity"  do 
  #  e = Intrigue::EntityManager.create_or_merge "test", "Domain", "!!!!bad!.com", {}
  #  expect(e).to be(nil)
  #end


end
end
