require 'sinatra'
require 'sinatra/contrib'

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

require 'redis'
require 'timeout'
require 'json'
require 'rest-client'

# Debug
require 'pry'

###
### START CONFIG
### XXX - this is not threadsafe :(
###
begin
  $intrigue_global_timeout = 900
  $intrigue_basedir = File.dirname(__FILE__)
  # Check to see if the config exists
  config_file = "#{$intrigue_basedir}/config/config.json"
  default_config_file = "#{$intrigue_basedir}/config/config.json.default"

  # Load up default config (which may include new fields)
  $intrigue_default_config = JSON.parse File.read(default_config_file)

  if File.exist? config_file
    # Okay, so we have a file - lets load that
    $intrigue_config = JSON.parse File.read(config_file)

    $intrigue_config = $intrigue_default_config.merge $intrigue_config

    # Check to make sure we have an engine_id config
    if $intrigue_config["intrigue_engine_id"]["value"] == "XXX" or $intrigue_config["intrigue_engine_id"]["value"] == ""
      # we need to generate it
      $intrigue_config["intrigue_engine_id"]["value"] = SecureRandom.uuid
    end
  else  # No config exists
    # Create a blank config
    $intrigue_config = $intrigue_default_config
    # Create the Engine ID
    $intrigue_config["intrigue_engine_id"]["value"] = SecureRandom.uuid
  end

  # Regardless, write our config back to the file
  File.open(config_file, 'w') do |f|
    f.write JSON.pretty_generate($intrigue_config)
  end
rescue JSON::ParserError => e
  raise "FATAL: Unable to load config: #{e}"
end

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  #Setup redis for resque
  $intrigue_redis = Redis.new

  ###
  ### END CONFIG
  ###

  ###
  ### Helpers
  ###
  helpers do
    def h(text)
      Rack::Utils.escape_html(text)
    end
  end

  before do
    $intrigue_server_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  not_found do
    "Unable to find this content."
  end


  ###
  ### Main Application
  ###

  get '/' do
    redirect '/v1/'
  end

  namespace '/v1/?' do

    # Main Page
    get '/?' do
      stats = Sidekiq::Stats.new
      @failed = stats.failed
      @processed = stats.processed
      @queues = stats.queues

      erb :index
    end

    # NEWS!
    get '/news/?' do
      erb :news
    end

    require_relative "app/all"

  end
end


# Core libraries
require_relative 'lib/all'
