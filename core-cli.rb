#!/usr/bin/env ruby
require 'thor'
require 'json'
require 'rest-client'
require 'intrigue_api_client'
require 'pry' #DEBUG

class CoreCli < Thor

  def initialize(*args)
    super
    $intrigue_basedir = File.dirname(__FILE__)
    $config = JSON.parse File.open("#{$intrigue_basedir}/config/config.json").read
    @server_uri = ENV.fetch("INTRIGUE_API_URI", "http://#{$config["credentials"]["username"]}:#{$config["credentials"]["password"]}@127.0.0.1:7777/v1")
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

  desc "start [Project Name] [Task] [Type#Entity] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy Name]", "Start a single task within a project."
  def start(project_name,task_name,entity_string,depth=1,option_string=nil,handler_string=nil, strategy_name="discovery")

    # Do the setup
    entity_hash = _parse_entity entity_string
    options_list = _parse_options option_string
    handler_list = _parse_handlers handler_string
    depth = depth.to_i

    ### Create a project
    @api.create_project(project_name)

    # Get the response from the API
    #puts "[+] Starting Task."

    response = @api.start(project_name,task_name,entity_hash,depth,options_list,handler_list, strategy_name)
    #puts "[D] Got response: #{response}" if @debug
    #unless response
    #  puts "Error retrieving response. Failing."
    #  return
    #end
    #puts "[+] Task complete!"

    # Parse the response
    #puts "[+] Start Results"
    #response["entities"].each do |entity|
    #  puts "[x] #{entity["type"]}#{@delim}#{entity["name"]}"
    #end
    #puts "[+] End Results"

    # Print the task log
    #response["log"].each_line{|x| puts "[L] #{x}" } if response["log"]
    #puts "response #{response}"
  end

  ###
  ### LOCAL ONLY
  ### XXX - rewrite this so it uses the API
  ###

  desc "local_handle_scan_results [Project] [Handler]", "Manually run a handler on a project's scan results"
  def local_handle_scan_results(project, handler_type)
    require_relative 'core'

    ### handle scan results
    Intrigue::Model::Project.each do |p|
      next unless p.name == project || project == "-"
      p.scan_results.each do |s|

        # Save our automatic handlers
        # XXX - HACK
        old_handlers = s.handlers
        s.handlers = [ handler_type ]
        s.save

        puts "[_] Handling: #{s.name}"
        s.handle_result # Force the handling with the second argumnent

        # Re-assign the old handlers
        # XXX - HACK
        s.handlers = old_handlers
        s.save
      end
    end

  end

  desc "local_handle_task_results [Project] [Handler]", "Manually run a handler on a project's task results"
  def local_handle_task_results(project,handler_type)
    require_relative 'core'

    ### handle task results
    Intrigue::Model::Project.each do |p|
      next unless p.name == project || project == "-"
      s = p.task_results.each do |t|

        puts "[x] Handling... #{t.name}"
        handler = Intrigue::HandlerFactory.create_by_type(handler_type)
        handler.process(t)

      end
    end

  end

  desc "local_load [Task] [File] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy]", "Load entities from a file and runs a task on each in a new project."
  def load(task_name,filename,depth=1,options_string=nil,handler_string=nil, strategy_name="discovery")

    # Load in the main core file for direct access to TaskFactory and the Tasks
    # This makes this super speedy.
    require_relative 'core'
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

      puts "entity: #{entity}"

      payload = {
        "task" => task_name,
        "entity" => entity,
        "options" => options,
      }

      task_result_id = SecureRandom.uuid

      # Check if the entity already exists, and if not, create a new entity
      type_class = eval("Intrigue::Entity::#{entity["type"]}")
      e = Intrigue::Model::Entity.scope_by_project_and_type(project_name, type_class).first(:name => entity["details"]["name"])

      unless e
        e = Intrigue::Model::Entity.create({
          :type => type_class.to_s,
          :name => entity["details"]["name"],
          :details => entity["details"],
          :project => p
        })
      end

      task_result = start_task("task", p, nil, task_name, e, depth, options, handlers, strategy_name)

      puts "Created task #{task_result.inspect} for entity #{e}"
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
      "details" => { "name" => entity_name}
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
