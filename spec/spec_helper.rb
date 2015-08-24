require_relative '../core.rb'
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

###
### Integration test helpers
#
# XXX - this should be updated to use the gem
#
###
module Intrigue
  module Test
    module Integration

      def server_uri
        "http://127.0.0.1:7777"
      end

      def task_list
        tasks_hash = JSON.parse(RestClient.get("#{server_uri}/tasks.json"))
      end

      def task_info
        task_info = JSON.parse(RestClient.get("#{server_uri}/tasks/#{task_name}.json"))
      end

      def task_start(task_name,entity,options=nil)

        payload = {
          :task => task_name,
          :options => options,
          :entity => entity
        }

        ###
        ### Send to the server
        ###
        task_id = RestClient.post "#{server_uri}/task_runs", payload.to_json, :content_type => "application/json"

        task_id
      end


      def task_start_and_wait(task_name,entity,options=nil)
        ###
        ### Construct the request
        ###
        task_id = task_start(task_name,entity,options)

        ###
        ### XXX - wait for the appropriate amount of time to collect
        ###  the response
        ###
        complete = false
        until complete
          sleep 1
          complete = true if(RestClient.get("#{server_uri}/task_runs/#{task_id}/complete") == "true")
        end

        ###
        ### Get the response
        ###
        response = JSON.parse(RestClient.get "#{server_uri}/task_runs/#{task_id}.json")
      end

    end
  end
end
