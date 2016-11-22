require 'sinatra'
require 'sinatra/contrib'
require 'json'
require 'rest-client'
require 'cgi'
require 'uri'

# Sidekiq
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

# Datamapper
require 'dm-core'
require 'dm-noisy-failures'
require 'dm-pager'
require 'dm-pg-types'
require 'dm-serializer'
require 'dm-validations'

# Debug
require 'pry'
require_relative 'lib/config/global_config'

$intrigue_global_timeout = 9000
$intrigue_basedir = File.dirname(__FILE__)

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
  #DataMapper::Logger.new($stdout, :warn)
  DataMapper::Logger.new(STDOUT, :warn)

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

  # Run our setup with the correct enviroment
  DataMapper.setup(:default, database_config[system_env])
  DataMapper::Property::String.length(255)
end

sanity_check_system
setup_datamapper

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :sessions => true

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

  ###
  ### (Very) Simple Auth
  ###
  global_config = Intrigue::Config::GlobalConfig.new
  if global_config
    if global_config.config["http_security"]
      use Rack::Auth::Basic, "Restricted" do |username, password|
        [username, password] == [
          global_config.config["credentials"]["username"],
          global_config.config["credentials"]["password"]
        ]
      end
    end
  end

  before do

    # TODO - use settings helper going forward
    $intrigue_server_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"

    # Parse out our project
    project_string = request.path_info.split("/")[2] || "Default"

    # Allow certain requests without a project string
    pass if [ "project", "tasks", "tasks.json", "entity_types.json", nil].include? project_string

    # Set the project based on the project_string
    project = Intrigue::Model::Project.first(:name => project_string)

    # If we haven't resolved a project, let's handle it
    unless project
      # Creating a default project since it doesn't appear to exist (it should always exist)
      if project_string == "Default"
        project = Intrigue::Model::Project.create(:name => "Default")
      else
        halt
      end
    end

    # Set it so we can use it going forward
    @project_name = project.name
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

  # Application libraries
  require_relative "app/all"

  namespace '/v1/?' do

    # Main Page
    get '/?' do
      erb :index
    end

    # Main Page
    get '/:project/?' do
      erb :index
    end

    # NEWS!
    get '/:project/news/?' do
      erb :news
    end

  end
end

# Core libraries
require_relative "lib/all"
DataMapper.finalize
