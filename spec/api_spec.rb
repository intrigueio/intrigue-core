require 'spec_helper'

describe "Intrigue" do
describe "API" do

  it "should redirect to the current version" do
    get "/"
    expect(last_response.status).to match 302
  end

  it "should have v1 as the current version" do
    get "/"
    expect(last_response.status).to match 200
  end

  it "should return a list of tasks" do
    get '/tasks.json'
    expect(last_response.status).to match 200
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
