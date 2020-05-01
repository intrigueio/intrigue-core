require_relative 'spec_helper'

describe "Intrigue" do
describe "API" do

  #it "should return a 200" do
  #  get "/"
  #  expect(last_response.status).to match 200
  #end

end

describe "EntityApi" do 

  it "should return a list of entity types" do
    get '/entity_types.json'
    expect(last_response.status).to match 200
  end

  it "the entity list should contain a AutonomousSystem type" do
    get '/entity_types.json'
    json = JSON.parse(last_response.body)
    expect(json).not_to be nil 
    as = json.select{|x| x["name"] == "AutonomousSystem"} 
    expect(as).not_to be nil
  end

end

describe "TaskApi" do
  it "should return a list of tasks" do
    get '/tasks.json'
    expect(last_response.status).to match 200
  end

  it "entity list should contain a AutonomousSystem type" do
    get '/entity_types.json'
    json = JSON.parse(last_response.body)
    expect(json).not_to be nil 
    as = json.select{|x| x["name"] == "AutonomousSystem"} 
    expect(as).not_to be nil
  end

=begin
  it "should perform an example task" do

    header 'Content-Type', 'application/json'

    post "/Default/task_results", {
      :task => "example",
      :entity => {
        :type => "Host",
        :details => {
          :name => "test.com"
        }
      }
    }.to_json

    # It should return a 200
    expect(last_response.status).to match 200

    ###
    ### Request the task results
    ###
    get "/tasks/#{last_response.body}.json"

    # It should return a 200 with json as a response
    expect(last_response.status).to match 200
    expect(last_request.env["CONTENT_TYPE"]).to match "application/json"

  end
=end

end

end
