require 'sinatra'
require 'sinatra/contrib'
require 'json'
require 'rest-client'

# Sidekiq
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

# Datamapper
require 'dm-core'
require 'dm-serializer'
require 'dm-pg-types'
require 'dm-noisy-failures'
require 'dm-pager'

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
    "#{$intrigue_basedir}/config/sidekiq-scan.yml",
    "#{$intrigue_basedir}/config/sidekiq-task.yml",
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

# all datamapper set up stuffs
def setup_datamapper
  ##  Set up Database Logging
  DataMapper::Logger.new($stdout, :warn)

  # Get the database environment from our intrigue config
  database_environment = ENV.fetch('INTRIGUE_ENV', "#{$intrigue_config["intrigue_environment"]["value"]}")
  puts "Intrigue-core database environment: #{database_environment}"

  # Pull out the database config
  database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")

  # Catch an environment misconfiguraiton
  unless database_config[database_environment]
    puts "FATAL! No database config by the name: #{database_environment}"
    exit
  end

  # If we've been passed a database server (like with the docker config)
  # go ahead and set that in the config
  if ENV["POSTGRES_SERVER"]
    if database_config[database_environment]["host"]
      puts "WARNING! Overwriting database configuration based on POSTGRES_SERVER configuration #{ENV["POSTGRES_SERVER"]}"
      database_config[database_environment]["host"] = ENV["POSTGRES_SERVER"]
    end
  end

  puts "Database config: #{database_config[database_environment]}"

  # Run our setup with the correct enviroment
  DataMapper.setup(:default, database_config[database_environment])
  DataMapper::Property::String.length(255)
end

sanity_check_system_configuration
setup_datamapper

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  #Setup redis for resque
  #$intrigue_redis = Redis.new(url: 'redis://localhost:6379', namespace: 'intrigue')

  # set sidekiq options
  Sidekiq.configure_server do |config|
    redis_uri = ENV.fetch("REDIS_SERVER",$intrigue_config["intrigue_redis_uri"]["value"])
    config.redis = { url: "#{redis_uri}", namespace: 'intrigue' }
  end

  Sidekiq.configure_client do |config|
    redis_uri = ENV.fetch("REDIS_SERVER",$intrigue_config["intrigue_redis_uri"]["value"])
    config.redis = { url: "#{redis_uri}", namespace: 'intrigue' }
  end

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
      erb :news
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

DataMapper.finalize

# Create a default project for us to work in
Intrigue::Model::Project.create(:name => "default") unless Intrigue::Model::Project.first
