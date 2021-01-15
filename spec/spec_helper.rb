require_relative '../core'
require 'intrigue_api_client'
require 'rack/test'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false


def app
  IntrigueApp
end

#DB = Sequel.connect("sqlite:///tmp/test")
#Sequel::Model.db = DB

#puts "DB: #{DB}"
#puts "Sequel::Model.db: #{Sequel::Model.db}"

RSpec.configure do |c|
  c.include Rack::Test::Methods
  c.around(:each) do |example|
    #puts "Starting #{example.description}"
    example.run
    #puts "Cleaning up #{example.description}"
    #Intrigue::Core::Model::Project.all.each {|x| x.destroy }
    #Intrigue::Core::Model::Logger.all.each {|x| x.destroy }
    #Intrigue::Core::Model::ScanResult.all.each {|x| x.destroy }
    #Intrigue::Core::Model::TaskResult.all.each {|x| x.destroy }
    #Intrigue::Core::Model::Entity.all.each {|x| x.destroy }
    #puts "Ending #{example.description}"
  end
end
