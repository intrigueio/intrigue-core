require_relative '../core.rb'
require 'intrigue-api-client'
require 'rack/test'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  IntrigueApp
end

#Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
