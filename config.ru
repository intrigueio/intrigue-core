# -s puma
require './core'
require 'rack/protection'
require 'rack/cors'

###
### Configure CORS to be open 
###
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :options, :put]
  end
end

Sidekiq::Web.use Rack::Protection::AuthenticityToken

run Rack::URLMap.new({
  "/" => CoreApp,
  "/sidekiq" => Sidekiq::Web
})