require 'spec_helper'

describe "Intrigue Core API v1" do

  it "should return an index" do
    get '/'
    expect(last_response.status).to match 200
  end

  # Doesn't work with rack/test... why?
  #
  #it "should return the sidekiq interface" do
  #  get '/sidekiq'
  #  expect(last_response.status).to match 200
  #end

end
