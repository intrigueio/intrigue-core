require 'spec_helper'

describe "Intrigue" do
describe "Task API v1" do

  it "should return a list of tasks" do
    get '/v1/tasks.json'
    expect(last_response.status).to match 200
  end

  it "should return a list of task runs" do
    get '/v1/task_runs.json'
    expect(last_response.status).to match 200
  end

  it "should perform an example task" do

    header 'Content-Type', 'application/json'

    post "/v1/task_runs", {
      :task => "example",
      :entity => {
        :type => "DnsRecord",
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
    get "/v1/tasks/#{last_response.body}.json"

    # It should return a 200 with json as a response
    expect(last_response.status).to match 200
    expect(last_request.env["CONTENT_TYPE"]).to match "application/json"

  end

end
end
