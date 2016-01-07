require 'sinatra'
require 'sinatra/contrib'

require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

require 'dm-core'
require 'dm-serializer'
require 'dm-pg-types'
require 'dm-noisy-failures'
require 'dm-pager'

#require 'timeout'
require 'json'
require 'rest-client'

# Debug
require 'pry'

$intrigue_global_timeout = 9000
$intrigue_basedir = File.dirname(__FILE__)
$intrigue_config = JSON.parse File.read("#{$intrigue_basedir}/config/config.json")

#
# Simple configuration check to ensure we have configs in place
def sanity_check_system_configuration
  configuration_files = [
    "#{$intrigue_basedir}/config/config.json",
    "#{$intrigue_basedir}/config/database.yml",
    "#{$intrigue_basedir}/config/sidekiq.yml",
    "#{$intrigue_basedir}/config/puma.rb"
  ]
  configuration_files.each do |file|
    unless File.exist? file
      puts "ERROR! Missing configuration file! Cowardly refusing to start."
      puts "Missing file: #{file}"
      exit -1
    end
  end

end

sanity_check_system_configuration

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  #Setup redis for resque
  $intrigue_redis = Redis.new(url: 'redis://redis:6379', namespace: 'intrigue')

  # set sidekiq options
  Sidekiq.configure_server do |config|
    config.redis = { url: 'redis://redis:6379/', namespace: 'intrigue' }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: 'redis://redis:6379', namespace: 'intrigue' }
  end

  ##  Set up Database Logging
  DataMapper::Logger.new($stdout, :warn)

  # Get the database environment from our intrigue config
  database_environment = ENV.fetch('INTRIGUE_ENV', "#{$intrigue_config["intrigue_environment"]["value"]}")
  puts "Intrigue-core database environment: #{database_environment}"

  # Pull out the database config
  database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")
  exit unless database_config[database_environment]

  # Run our setup with the correct enviroment
  DataMapper.setup(:default, database_config[database_environment])
  DataMapper::Property::String.length(255)

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
      @stats = Sidekiq::Stats.new
      @workers = Sidekiq::Workers.new
      erb :index
    end

    # NEWS!
    get '/news/?' do
      erb :news
    end

  end
end


# Application libraries
require_relative "app/all"

# Core libraries
require_relative 'lib/all'

# Call finalize now that we have all models loaded
DataMapper.finalize

# Create a default project for us to work in
Intrigue::Model::Project.create(:name => "default") unless Intrigue::Model::Project.first
