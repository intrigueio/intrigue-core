require 'spec_helper'

describe "Intrigue" do
describe "Core API" do

  it "should redirect to the current API" do
    get "/"
    expect(last_response.status).to match 302
  end

  it "should have v1 as the current version" do
    get "/v1/"
    expect(last_response.status).to match 200
  end

end
end
