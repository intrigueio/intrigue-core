require 'eventmachine'
require 'logger'
require 'sinatra'
require 'sinatra/contrib'
require 'yaml'
require 'rest-client'
require 'cgi'
require 'uri'
require 'shellwords' # shell escapin'

# Improved Json memory efficiency
require 'yajl'
require 'yajl/json_gem'

# Sidekiq
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'sidekiq-limit_fetch'

# Global vars
$intrigue_basedir = File.dirname(__FILE__)
$intrigue_environment = ENV.fetch("INTRIGUE_ENV","development")

# System-level Monkey patches
require_relative 'lib/initialize/array'
require_relative 'lib/initialize/hash'
require_relative 'lib/initialize/json_export_file'
require_relative 'lib/initialize/queue'
require_relative 'lib/initialize/sidekiq_profiler'
require_relative 'lib/initialize/string'

# load up our system config
require_relative 'lib/system/config'
Intrigue::Core::System::Config.load_config

# system database configuration
require_relative 'lib/system/database'
include Intrigue::Core::System::Database

# used in app as well as tasks
require_relative 'lib/system/validations'
include Intrigue::Core::System::Validations

# used in app as well as tasks
require_relative 'lib/system/helpers'
include Intrigue::Core::System::Helpers

# Debug
require 'logger'

# disable annoying redis messages 
Redis.exists_returns_integer = false

#
# Simple configuration check to ensure we have configs in place
def sanity_check_system
  configuration_files = [
    "#{$intrigue_basedir}/config/config.json",
    "#{$intrigue_basedir}/config/database.yml",
    "#{$intrigue_basedir}/config/sidekiq.yml",
    "#{$intrigue_basedir}/config/redis.yml",
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

def setup_redis
  redis_config = YAML.load_file("#{$intrigue_basedir}/config/redis.yml")
  $redis_host = ENV["REDIS_HOST"] || redis_config[$intrigue_environment]["host"] || "localhost"
  $redis_port = ENV["REDIS_PORT"] || redis_config[$intrigue_environment]["port"] || 6379
  $redis_connect_string = "redis://#{$redis_host}:#{$redis_port}/"

  # Pull sidekiq config from the environment if it's available (see docker config)
  Sidekiq.configure_server do |config|
    # configure the ur
    puts "Connecting to Redis Server at: #{$redis_connect_string}"
    config.redis = { url: $redis_connect_string}
  end
  # configure the client
  Sidekiq.configure_client do |config|
    puts "Configuring Redis Client for: #{$redis_connect_string}"
    config.redis = { :url => $redis_connect_string }
  end
end

sanity_check_system
setup_redis unless ENV["INTRIGUE_ENV"] == "test"
setup_database

class CoreApp < Sinatra::Base
  register Sinatra::Namespace

  set :allow_origin, "https://localhost:7778"
  set :allow_methods, "GET,HEAD,POST"
  set :allow_headers, "content-type,if-modified-since,allow"
  set :expose_headers, "location,link"
  set :allow_credentials, true

  set :sessions => true
  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  if Intrigue::Core::System::Config.config["debug"]
    set :logging, true
  end

  ###
  ### Helpers
  ###
  helpers do
    def h(text)
      CGI::escapeHTML "#{text}"
    end
  end

  ###
  ### (Very) Simple Auth
  ###
  if Intrigue::Core::System::Config.config
    if Intrigue::Core::System::Config.config["http_security"]
      use Rack::Auth::Basic, "Restricted" do |username, password|
        [username, password] == [
          Intrigue::Core::System::Config.config["credentials"]["username"],
          Intrigue::Core::System::Config.config["credentials"]["password"]
        ]
      end
    end
  else
    puts "FATAL!! unable to access global config, cowardly refusing to start."
  end


  before do

    # TODO - use settings helper going forward
    $intrigue_server_uri = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"

    # Parse out our project
    directive = URI.unescape(request.path_info.split("/")[1] || "Default")

    # set flash message if we have one
    if session[:flash]
      @flash = session[:flash]
      session[:flash] = nil
    end

    # Allow certain requests without a project string... these are systemwide,
    # and do not depend on a specific project
    pass if [ "api", "entity_types.json", "engine", "favicon.ico",
              "project", "tasks", "tasks.json",
              "version.json", "system", nil ].include? directive
    pass if request.path_info =~ /\.js$/ # all js
    pass if request.path_info =~ /\.css$/ # all css
    pass if request.path_info =~ /(.jpg|.png)$/ # all images

    # Set the project based on the directive
    project = Intrigue::Core::Model::Project.first(:name => directive)

    # If we haven't resolved a project, let's handle it
    unless project
      # Creating a default project since it doesn't appear to exist (it should always exist)
      if directive == "Default"
        project = Intrigue::Core::Model::Project.create(:name => "Default", :created_at => Time.now.utc )
      else
        redirect "/"
      end
    end

    # Set it so we can use it going forward
    @project_name = project.name
  end

  not_found do
    "Unable to find this content."
  end

  ###                                  ###
  ### App-Level Constants              ###
  ###                                  ###

  FRONT_PAGE = "/"

  ###                                    ###
  ### App-Level Informational API Calls  ###
  ###                                    ###

  # Return a JSON array of all entity type
  get '/entity_types.json' do
    content_type 'application/json'
    Intrigue::EntityFactory.entity_types.map{ |e| e.metadata }.sort_by{|m| m[:name] }.to_json
  end

  # Export All Tasks
  get '/tasks.json/?' do
    content_type 'application/json'
    Intrigue::TaskFactory.list.map{ |t| t.metadata }.sort_by{|m| m[:name] }.to_json
  end

  # Export a single task
  get '/tasks/*.json/?' do
    content_type 'application/json'
    task_name = params[:splat][0..-1].join('/')
    Intrigue::TaskFactory.list.select{|t| t.metadata[:name] == task_name }.first.metadata.to_json
  end

  # Application libraries
  require_relative "app/all"

end

# Core libraries
require_relative "lib/all"

# Monkey patches, post load
require_relative 'lib/initialize/excon'

# use redirect following w/ excon
Excon.defaults[:middlewares] << Excon::Middleware::RedirectFollower


#configure sentry.io error reporting (only if a key was provided)
if (Intrigue::Core::System::Config.config && Intrigue::Core::System::Config.config["sentry_dsn"])
  require "raven"
  puts "!!! Configuring Sentry error reporting to: #{Intrigue::Core::System::Config.config["sentry_dsn"]}"

  Raven.configure do |config|
    config.dsn = Intrigue::Core::System::Config.config["sentry_dsn"]
  end
end
