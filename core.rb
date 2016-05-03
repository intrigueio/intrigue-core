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
require_relative 'lib/config/global'

$intrigue_global_timeout = 9000
$intrigue_basedir = File.dirname(__FILE__)
$intrigue_config = Intrigue::Config::Global.new.dump_json
#
# Simple configuration check to ensure we have configs in place
def sanity_check_system
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

  # Pull intrigue config from the environment if it's available (see docker config)
  system_env = ENV.fetch("INTRIGUE_ENV", "development")
  puts "Intrigue-core system environment: #{system_env}"

  # Pull out the database config
  database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")
  unless database_config[system_env]
    # Catch an environment misconfiguration
    puts "FATAL! No database config by the name: #{system_env}"
    exit
  end

  #puts "DEBUG: Database config: #{database_config[system_env]}"

  # Run our setup with the correct enviroment
  DataMapper.setup(:default, database_config[system_env])
  DataMapper::Property::String.length(255)
end

sanity_check_system
setup_datamapper

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  # Pull sidekiq config from the environment if it's available (see docker config)
  Sidekiq.configure_server do |config|
    redis_uri = ENV.fetch("REDIS_URI","redis://localhost:6379/")
    config.redis = { url: "#{redis_uri}", namespace: 'intrigue' }
  end

  Sidekiq.configure_client do |config|
    redis_uri = ENV.fetch("REDIS_URI","redis://localhost:6379/")
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
require_relative "lib/all"

DataMapper.finalize

# Create a default project for us to work in
Intrigue::Model::Project.create(:name => "default") unless Intrigue::Model::Project.first
