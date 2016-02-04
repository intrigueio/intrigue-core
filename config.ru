# -s puma
require './core'
require 'rack/protection'

Sidekiq::Web.use Rack::Protection::AuthenticityToken

# Necessary because of CSRF protection added in 3.4.2
# https://github.com/mperham/sidekiq/issues/2459
#Sidekiq::Web.use Rack::Session::Cookie, :secret => File.read(".session-secret")
#Sidekiq::Web.instance_eval { @middleware.rotate!(-1) }

run Rack::URLMap.new({
  "/" => IntrigueApp,
  "/sidekiq" => Sidekiq::Web
})
