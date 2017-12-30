require 'logger'


require 'sinatra'
require 'sinatra/contrib'
require 'json'
require 'yaml'
require 'rest-client'
require 'cgi'
require 'uri'

# Sidekiq
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'

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
require_relative 'lib/initialize/capybara'
require_relative 'lib/initialize/hash'
require_relative 'lib/initialize/sidekiq_profiler'
require_relative 'lib/initialize/string'

$intrigue_basedir = File.dirname(__FILE__)

#
# Simple configuration check to ensure we have configs in place
def sanity_check_system
  configuration_files = [
    "#{$intrigue_basedir}/config/config.json",
    "#{$intrigue_basedir}/config/database.yml",
    "#{$intrigue_basedir}/config/sidekiq-task-interactive.yml",
    "#{$intrigue_basedir}/config/sidekiq-task-autoscheduled.yml",
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

# database set up
def setup_database
  options = {
    :max_connections => 16,
    :pool_timeout => 240
  }

  if Intrigue::Config::GlobalConfig.new.config["debug"]
    options.merge({:loggers => [Logger.new($stdout)]})
  end

  environment = "development"
  database_config = YAML.load_file("#{$intrigue_basedir}/config/database.yml")
  database_host = database_config[environment]["host"]
  database_user = database_config[environment]["user"]
  database_pass = database_config[environment]["pass"]
  database_name = database_config[environment]["database"]

  $db = Sequel.connect("postgres://#{database_user}@#{database_host}:5432/#{database_name}", options)

  # Allow datasets to be paginated
  Sequel::Database.extension :pagination
  Sequel::Database.extension :pg_json
  Sequel.extension :pg_json_ops
end

sanity_check_system
setup_database

class IntrigueApp < Sinatra::Base
  register Sinatra::Namespace

  set :sessions => true
  set :root, "#{$intrigue_basedir}"
  set :views, "#{$intrigue_basedir}/app/views"
  set :public_folder, 'public'

  if Intrigue::Config::GlobalConfig.new.config["debug"]
    set :logging, true
  end

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
      CGI::escapeHTML "#{text}"
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
    project_string = URI.unescape(request.path_info.split("/")[1] || "Default")
    #puts "Got Project string: #{project_string}"

    # Allow certain requests without a project string... these are systemwide,
    # and do not depend on a specific project
    pass if ["favicon.ico", "project", "tasks", "tasks.json", "entity_types.json", "version.json", nil].include? project_string
    pass if request.path_info =~ /js$/ # if we're submitting a new task result via api
    pass if request.path_info =~ /css$/ # if we're submitting a new task result via api
    pass if request.path_info =~ /(.jpg|.png)$/ # if we're submitting a new task result via api
    pass if request.path_info =~ /linkurious/ # if we're submitting a new task result via api

    # Set the project based on the project_string
    project = Intrigue::Model::Project.first(:name => project_string)

    # If we haven't resolved a project, let's handle it
    unless project
      # Creating a default project since it doesn't appear to exist (it should always exist)
      if project_string == "Default"
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
    Intrigue::Model::Entity.descendants.map{ |x| x.metadata }.to_json
  end

  # Export All Tasks
  get '/tasks.json/?' do
    content_type 'application/json'
    Intrigue::TaskFactory.list.map { |t| t.metadata }.to_json
  end

  # Export a single task
  get '/tasks/:task_name.json/?' do
    content_type 'application/json'
    task_name = params[:task_name]
    Intrigue::TaskFactory.list.select{|t| t.metadata[:name] == task_name}.first.metadata.to_json
  end

  # Application libraries
  require_relative "app/all"

end

# Core libraries
require_relative "lib/all"
