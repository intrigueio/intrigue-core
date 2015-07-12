# -s puma
require './core'

#run Sinatra::Application
run Rack::URLMap.new('/' => Sinatra::Application, '/sidekiq' => Sidekiq::Web)
