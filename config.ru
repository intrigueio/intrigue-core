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


#configure sentry.io error reporting (only if a key was provided) 
if (Intrigue::Config::GlobalConfig.config && Intrigue::Config::GlobalConfig.config["sentry_dsn"])

  require "raven"

  puts "!!! Configuring Sentry error reporting to: #{Intrigue::Config::GlobalConfig.config["sentry_dsn"]}"

  Raven.configure do |config|
    config.dsn = Intrigue::Config::GlobalConfig.config["sentry_dsn"]
  end

  use Raven::Rack
end