# -s puma
require './core'

Sidekiq::Web.use Rack::Session::Cookie, :secret => "SOMETHING SECRET"
Sidekiq::Web.instance_eval { @middleware.reverse! } # Last added, First Run

run Rack::URLMap.new({
  "/" => Sinatra::Application,
  #"/admin" => AdminApp,
  "/sidekiq" => Sidekiq::Web
})
