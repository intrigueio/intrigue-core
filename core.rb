require 'eventmachine'
require 'logger'
require 'sinatra'
require 'sinatra/contrib'
require 'yajl/json_gem'
require 'yaml'
require 'rest-client'
require 'cgi'
require 'uri'

# Sidekiq
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'sidekiq-limit_fetch'

# Database
require 'sequel'

# Config
require_relative 'lib/config/global_config'

# Debug
require 'pry'
require 'pry-byebug'
require 'logger'

# System-level Initializers
require_relative 'lib/initialize/array'
require_relative 'lib/initialize/browser'
require_relative 'lib/initialize/hash'
require_relative 'lib/initialize/json_export_file'
require_relative 'lib/initialize/sidekiq_profiler'
require_relative 'lib/initialize/string'


$intrigue_basedir = File.dirname(__FILE__)
$intrigue_environment = ENV.fetch("INTRIGUE_ENV","development")

# load up our config
Intrigue::Config::GlobalConfig.load_config

# Webdriver
Selenium::WebDriver.logger.level = :warn
Selenium::WebDriver.logger.output = "#{$intrigue_basedir}/log/selenium.log"

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
  redis_host = redis_config[$intrigue_environment]["host"] || "localhost"
  redis_port = redis_config[$intrigue_environment]["port"] || 6379

  # Pull sidekiq config from the environment if it's available (see docker config)
  Sidekiq.configure_server do |config|
    redis_uri = ENV.fetch("REDIS_URI","redis://#{redis_host}:#{redis_port}/")
    config.redis = { url: "#{redis_uri}" }
  end

end

# database set up
def setup_database
  database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")

  options = {
    :max_connections => database_config[$intrigue_environment]["max_connections"] || 20,
    :pool_timeout => database_config[$intrigue_environment]["pool_timeout"] || 240 
  }
  
  database_host = database_config[$intrigue_environment]["host"] || "localhost"
  database_port = database_config[$intrigue_environment]["port"] || 5432
  database_user = database_config[$intrigue_environment]["user"]
  database_pass = database_config[$intrigue_environment]["password"]
  database_name = database_config[$intrigue_environment]["database"]
  database_debug = database_config[$intrigue_environment]["debug"]

  if database_pass 
    $db = Sequel.connect("postgres://#{database_user}:#{database_pass}@#{database_host}:#{database_port}/#{database_name}", options)
  else
    $db = Sequel.connect("postgres://#{database_user}@#{database_host}:#{database_port}/#{database_name}", options)
  end

  $db.loggers << Logger.new($stdout) if database_debug

  # Allow datasets to be paginated
  $db.extension :pagination
  #$db.extension :pg_json
  Sequel.extension :pg_json_ops

  Sequel::Model.plugin :update_or_create
end

sanity_check_system
setup_redis
setup_database

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :sessions => true
  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  if Intrigue::Config::GlobalConfig.config["debug"]
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
  if Intrigue::Config::GlobalConfig.config
    if Intrigue::Config::GlobalConfig.config["http_security"]
      use Rack::Auth::Basic, "Restricted" do |username, password|
        [username, password] == [
          Intrigue::Config::GlobalConfig.config["credentials"]["username"],
          Intrigue::Config::GlobalConfig.config["credentials"]["password"]
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

    # Allow certain requests without a project string... these are systemwide,
    # and do not depend on a specific project
    pass if [ "entity_types.json", "engine", "favicon.ico", 
              "project", "tasks", "tasks.json", 
              "version.json", "system", nil ].include? directive
    pass if request.path_info =~ /\.js$/ # all js
    pass if request.path_info =~ /\.css$/ # all css
    pass if request.path_info =~ /(.jpg|.png)$/ # all images

    # Set the project based on the directive
    project = Intrigue::Model::Project.first(:name => directive)

    # If we haven't resolved a project, let's handle it
    unless project
      # Creating a default project since it doesn't appear to exist (it should always exist)
      if directive == "Default"
        project = Intrigue::Model::Project.create(:name => "Default")
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
  ### System-Level Informational Calls ###
  ###                                  ###

  # Return a JSON array of all entity type
  get '/entity_types.json' do
    content_type 'application/json'
    Intrigue::Model::Entity.descendants.map{ |e| e.metadata }.sort_by{|m| m[:name] }.to_json
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