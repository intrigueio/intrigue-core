require 'logger'
require 'sinatra'
require 'sinatra/contrib'
require 'yaml'
require 'rest-client'
require 'cgi'
require 'uri'
require 'shellwords' # shell escapin'

###
# Sidekiq - load in sidekiq pro if available
###
begin
  require 'sidekiq-pro'
  require 'sidekiq/pro/web'
rescue LoadError => e   # fall back to normal sidekiq
  require 'sidekiq'
  require 'sidekiq/web'
end

# always
require 'sidekiq/api'
require 'sidekiq-limit_fetch'

# Global vars
$intrigue_basedir = File.dirname(__FILE__)
$intrigue_environment = ENV.fetch("INTRIGUE_ENV","development")

## Content and data we simply dont want to keep re-opening. must be useful across all threads, and
## not be massive overhead. ideally this helps us avoid opening too many files in process.
$raw_suffix_list = File.open("#{$intrigue_basedir}/data/public_suffix_list.clean.txt").read.split("\n")

# Standard domain exceptions should only be read once
sne_file = "#{$intrigue_basedir}/data/standard_domain_exceptions.list"
$standard_domain_exceptions = File.open(sne_file).readlines.map{ |x| "#{x.strip}" }

Encoding.default_external="UTF-8"
Encoding.default_internal="UTF-8"

# System-level Monkey patches
require_relative 'lib/initialize/array'
require_relative 'lib/initialize/exceptions'
require_relative 'lib/initialize/hash'
require_relative 'lib/initialize/json_export_file'
require_relative 'lib/initialize/queue'
require_relative 'lib/initialize/resolv'
require_relative 'lib/initialize/sidekiq_profiler'
require_relative 'lib/initialize/string'
require_relative 'lib/initialize/symbol'
require_relative 'lib/initialize/typhoeus'

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
  $redis_pass = ENV["REDIS_PASS"] || redis_config[$intrigue_environment]["password"] || nil
  $redis_connect_string = "redis://#{$redis_host}:#{$redis_port}/"

  # Pull sidekiq config from the environment if it's available (see docker config)
  Sidekiq.configure_server do |config|

    puts "Connecting to Redis Server at: #{$redis_connect_string}"
    # if password is present, use it
    if $redis_pass
      config.redis = { url: $redis_connect_string, password: $redis_pass}
    else
      config.redis = { url: $redis_connect_string}
    end

    begin
      puts "Configuring reliable fetch if it's available!"
      config.super_fetch!
      config.reliable_scheduler!
    rescue NoMethodError => e
      # No reliable fetch available
    end

  end

  # configure the client
  Sidekiq.configure_client do |config|
    puts "Configuring Redis Client for: #{$redis_connect_string}"

    begin
      puts "Configuring reliable fetch if it's available!"
      config.reliable_push! if "#{ENV["APP_ENV"]}".strip == "production-engine"
    rescue NoMethodError => e
      # No reliable push available
    end


    # if password is present, use it
    if $redis_pass
      config.redis = { url: $redis_connect_string, password: $redis_pass}
    else
      config.redis = { url: $redis_connect_string}
    end
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
  ## Helpers
  ###
  helpers do
    def h(text)
      CGI::escapeHTML "#{text}"
    end
  end

  ###
  ## Enable CSRF Protection
  ###
  Sidekiq::Web.use(Rack::Session::Cookie, secret: ENV['SESSION_SECRET'] || SecureRandom.hex(60) )
  Sidekiq::Web.use Rack::Protection::AuthenticityToken

  ###
  ## Enable Basic Auth
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
    if request.path_info.split("/")[1]
      directive = URI.decode_www_form_component(request.path_info.split("/")[1])
    end

    # set flash message if we have one
    if session[:flash]
      @flash = session[:flash]
      session[:flash] = nil
    end

    # Allow certain requests without a project string... these are systemwide,
    # and do not depend on a specific project
    pass if [ "api", "entity_types.json", "engine", "favicon.ico",
              "project", "tasks", "tasks.json", "help",
              "version.json", "system", nil ].include? directive
    pass if request.path_info =~ /\.js$/ # all js
    pass if request.path_info =~ /\.css$/ # all css
    pass if request.path_info =~ /(.jpg|.png)$/ # all images

    # Set the project based on the directive
    project = Intrigue::Core::Model::Project.first(:name => directive)
    if project
      @project_name = project.name
    else
      session[:flash] = "Missing Project!?"
      redirect FRONT_PAGE
    end

  end

  not_found do
    status 404
    erb :oops
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

###
## Relevant to hosted/managed configurations, load in a Sentry DSN from
##   the so we can report errors to a Sentry instance
###
#configure sentry.io error reporting (only if a key was provided)
if (Intrigue::Core::System::Config.config && Intrigue::Core::System::Config.config["sentry_dsn"])
  require "sentry-ruby"
  require "sentry-sidekiq"
  puts "!!! Configuring Sentry error reporting to: #{Intrigue::Core::System::Config.config["sentry_dsn"]}"
  Sentry.init do |config|
    config.dsn = Intrigue::Core::System::Config.config["sentry_dsn"]
    config.breadcrumbs_logger = [:sentry_logger, :http_logger]
    config.traces_sample_rate = 0.2
  end
end

