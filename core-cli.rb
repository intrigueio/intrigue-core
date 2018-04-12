#!/usr/bin/env ruby
require 'thor'
require 'json'
require 'rest-client'
require 'intrigue_api_client'
require 'pp'
require 'pry' #DEBUG
require_relative 'core'

class CoreCli < Thor

  def initialize(*args)
    super
    $intrigue_basedir = File.dirname(__FILE__)
    $config = JSON.parse File.open("#{$intrigue_basedir}/config/config.json").read
    @server_uri = ENV.fetch("INTRIGUE_API_URI", "http://#{$config["credentials"]["username"]}:#{$config["credentials"]["password"]}@127.0.0.1:7777")
    @delim = "#"
    @debug = true
    # Connect to Intrigue API
    @api = IntrigueApi.new(@server_uri)
  end

  desc "create_project [project_name]", "Create a project"
  def create_project(project_name)
    puts "Creating project: #{project_name}"
    @api.create_project(project_name)
  end

  desc "list", "List all available tasks"
  def list
    puts "Available tasks:"
    tasks_hash = @api.list
    tasks_hash.each do |task|
      task_name = task["name"]
      task_description = task["description"]
      puts "Task: #{task_name} - #{task_description}"
    end
  end

  desc "info [Task Name]", "Show detailed about a task"
  def info(task_name)

    begin
      task_info = @api.info(task_name)

      puts "Name: #{task_info["name"]} (#{task_info["pretty_name"]})"
      puts "Description: #{task_info["description"]}"
      puts "Authors: #{task_info["authors"].join(", ")}"
      puts "---"
      puts "Allowed Types: #{task_info["allowed_types"].join(", ")}"

      puts "Options: "
      task_info["allowed_options"].each do |opt|
        puts " - #{opt["name"]} (#{opt["type"]})"
      end

      puts "Example Entities: "
      task_info["example_entities"].each do |x|
        puts " - #{x["type"]}##{x["attributes"]["name"]}"
      end

      puts "Creates: #{task_info["created_types"].join(", ")}"

    rescue RestClient::InternalServerError => e
      puts "No task found"
      puts "Exception #{e}"
      return
    end
  end

  desc "background [Project Name] [Task] [Type#Entity] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy Name] [Auto Enrich]", "Start a single task within a project."
  def background(project_name,task_name,entity_string,depth=1,option_string=nil,handler_string=nil, strategy_name=nil, auto_enrich=true)
    # Do the setup
    entity_hash = _parse_entity entity_string
    options_list = _parse_options option_string
    handler_list = _parse_handlers handler_string
    depth = depth.to_i

    @api.create_project(project_name)

    task_result_id = @api.background(project_name,task_name,entity_hash,depth,options_list,handler_list,strategy_name, auto_enrich)
    puts "Task Result: #{task_result_id}"
  end


  desc "start [Project Name] [Task] [Type#Entity] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy Name] [Auto Enrich]", "Start a single task within a project."
  def start(project_name,task_name,entity_string,depth=1,option_string=nil,handler_string=nil, strategy_name=nil, auto_enrich=true)

    # Do the setup
    entity_hash = _parse_entity entity_string
    options_list = _parse_options option_string
    handler_list = _parse_handlers handler_string
    depth = depth.to_i

    ### Create a project
    @api.create_project(project_name)

    # Get the response from the API
    puts "[+] Starting Task."
    @api.start(project_name,task_name,entity_hash,depth,options_list,handler_list,strategy_name, auto_enrich)
  end

  ###
  ### LOCAL ONLY
  ### XXX - rewrite this so it uses the API
  ###

  desc "local_handle_all_projects [Handler]", "Manually run a handler on a project's scan results"
  def local_handle_all_projects(handler_type)
    Intrigue::Model::Project.each do |p|
      puts "Running #{handler_type} on #{p.name}"
      p.handle(handler_type)
    end
  end

  desc "local_handle_all_projects_scan_results [Handler]", "Manually run a handler on a project's scan results"
  def local_handle_all_projects(handler_type)
    Intrigue::Model::Project.each do |p|
      puts "Working on #{p.name}..."
      p.scan_results.each {|s| s.handle(handler_type) }
    end
  end

  desc "local_handle_project [Project] [Handler]", "Manually run a handler on a project's scan results"
  def local_handle_project(project, handler_type)
    Intrigue::Model::Project.first(:name => project).handle(handler_type)
  end

  desc "local_handle_scan_results [Project] [Handler]", "Manually run a handler on a project's scan results"
  def local_handle_scan_results(project, handler_type)

    ### handle scan results
    Intrigue::Model::Project.each do |p|
      next unless p.name == project || project == "-"
      p.scan_results.each do |s|
        puts "[x] Handling... #{s.name}"
        s.handle(handler_type)
      end
    end

  end

  desc "local_handle_task_results [Project] [Handler]", "Manually run a handler on a project's task results"
  def local_handle_task_results(project,handler_type)

    ### handle task results
    Intrigue::Model::Project.each do |p|
      next unless p.name == project || project == "-"
      s = p.task_results.each do |t|
        puts "[x] Handling... #{t.name}"
        t.handle(handler_type)
      end
    end
  end

  desc "local_load [Task] [File] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy]", "Load entities from a file and runs a task on each in a new project."
  def local_load(task_name,filename,depth=1,options_string=nil,handler_string=nil, strategy_name="asset_discovery_active")

    # Load in the main core file for direct access to TaskFactory and the Tasks
    # This makes this super speedy.
    extend Intrigue::Task::Helper

    lines = File.open(filename,"r").readlines

    project_name = "#{task_name}-#{Time.now.strftime("%Y%m%d%H%M%s")}"
    p = Intrigue::Model::Project.create(:name => project_name)

    lines.each do |line|
      line.chomp!

      entity = _parse_entity line
      options = _parse_options options_string
      handlers = _parse_handlers handler_string
      depth = depth.to_i

      #puts "Entity: #{entity}"
      #puts "Strategy: #{strategy_name}"

      payload = {
        "task" => task_name,
        "entity" => entity,
        "options" => options,
      }

      # Create the entity
      entity = Intrigue::EntityManager.create_first_entity(project_name, entity["type"], entity["details"]["name"], entity["details"], true)

      # kick off the task
      task_result = start_task("task", p, nil, task_name, entity, depth, options, handlers, strategy_name)
      puts "Created task #{task_result.inspect} for entity #{entity}"
    end
  end

private


  # parse out entity from the cli
  def _parse_entity(entity_string)
    entity_type = entity_string.split(@delim).first
    entity_name = entity_string.split(@delim).last

    entity_hash = {
      "type" => entity_type,
      "name" => entity_name,
      "details" => { "name" => entity_name }
    }

    puts "Got entity: #{entity_hash}" if @debug

  entity_hash
  end

  # Parse out options from cli
  def _parse_options(option_string)

      return [] unless option_string

      options_list = []
      options_list = option_string.split(@delim).map do |option|
        { "name" => option.split("=").first, "value" => option.split("=").last }
      end

      puts "Got options: #{options_list}" if @debug

  options_list
  end

  # Parse out options from cli
  def _parse_handlers(handler_string)
      return [] unless handler_string

      handler_list = []
      handler_list = handler_string.split(",")

      puts "Got handlers: #{handler_list}" if @debug

  handler_list
  end

end # end class

CoreCli.start
