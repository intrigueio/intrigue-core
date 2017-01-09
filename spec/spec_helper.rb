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
  DB = Sequel.sqlite
  config.around(:each) do |example|
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){example.run}
  end

end
