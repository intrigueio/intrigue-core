require_relative 'spec_helper'

describe "Intrigue" do
describe "Models" do
describe "Project" do

  #https://relishapp.com/rspec/rspec-core/v/2-0/docs/hooks/before-and-after-hooks
  before(:all) do 
    @p = Intrigue::Core::Model::Project.create(name: "test")
  end

  after(:all) do 
    Intrigue::Core::Model::Project.truncate 
  end

  it "can be created" do
    expect(@p.name).to eq("test")
  end

  it "can be deleted" do
    expect(@p.delete!).to eq(true)
  end

end
end
end
