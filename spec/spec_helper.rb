require_relative '../core.rb'
require 'intrigue_api_client'
require 'rack/test'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  IntrigueApp
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

@project = Intrigue::Model::Project.create(:name => "TEST!") unless Intrigue::Model::Project.first(:name => "TEST!")
