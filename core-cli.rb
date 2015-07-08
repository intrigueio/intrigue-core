#!/usr/bin/env ruby

require 'thor'
require 'json'
require 'rest-client'

#DEBUG
require 'pry'

require_relative 'core'

class IntrigueCli < Thor

  def initialize(*args)
    super

    $intrigue_basedir = File.dirname(__FILE__)

    # Set the appropriate environment
    if ENV["INTRIGUE_ENV"] == "production"
      @server_uri = "http://core.intrigue.io/v1"
    else
      @server_uri = "http://localhost:5000/v1"
    end

    @delim = "#"
  end

  desc "list", "List all available tasks"
  def list
    puts "Available tasks:"
    tasks_hash = JSON.parse(RestClient.get("#{@server_uri}/tasks.json"))
    tasks_hash.each do |task|
      task_name = task["name"]
      task_description = task["description"]
      puts "Task: #{task_name} - #{task_description}"
    end
  end

  desc "info [Task]", "Show detailed about a task"
  def info(task_name)

    begin
      task_info = JSON.parse(RestClient.get("#{@server_uri}/tasks/#{task_name}.json"))

      puts "Name: #{task_info["name"]} (#{task_info["pretty_name"]})"
      puts "Description: #{task_info["description"]}"
      puts "Authors: #{task_info["authors"].join(", ")}"
      puts "---"
      puts "Allowed Types: #{task_info["allowed_types"].join(", ")}"

      puts "Options: "
      task_info["allowed_options"].each do |opt|
        puts " - #{opt["name"]} (#{opt["type"]})"
      end

      puts "Example Entities:"

      task_info["example_entities"].each do |x|
        puts " - #{x["type"]}:#{x["attributes"]["name"]}"
      end

      puts "Creates: #{task_info["created_types"].join(", ")}"

    rescue RestClient::InternalServerError => e
      puts "No task found"
      puts "Exception #{e}"
      return
    end

  end

  desc "start_and_background [Task] [Type#Entity] [Option1=Value1#...#...]", "Start a task"
  def start_and_background(task_name,entity,options=nil)

    entity_type = entity.split(@delim).first
    entity_name = entity.split(@delim).last

    entity_hash = {
      :type => entity_type,
      :attributes => { :name => entity_name}
    }

    # Parse out options
    if options
      options_list = options.split(@delim).map do |option|
        { :name => option.split("=").first, :value => option.split("=").last }
      end
    end

    payload = {
      :task => task_name,
      :options => options_list,
      :entity => entity_hash
    }

    ###
    ### Send to the server
    ###

    task_id = RestClient.post "#{@server_uri}/task_runs", payload.to_json, :content_type => "application/json"
    #puts "#{@server_uri}/task_runs/#{task_id}" if task_id

    task_id
  end

  desc "start [Task] [Type#Entity] [Option1=Value1#...#...]", "Start a task and wait for the result"
  def start(task_name,entity,options=nil)

    ###
    ### Construct the request
    ###
    puts "[+] Starting task"
    task_id = start_and_background(task_name,entity,options)

    ###
    ### XXX - wait for the appropriate amount of time to collect
    ###  the response
    ###
    complete = false
    until complete
      sleep 1
      complete = true if(RestClient.get("#{@server_uri}/task_runs/#{task_id}/complete") == "true")
    end

    puts "[+] Task complete!"


    ###
    ### Get the response
    ###
    puts "[+] Start Results"
    response = JSON.parse(RestClient.get "#{@server_uri}/task_runs/#{task_id}.json")
    response["entities"].each do |entity|
      puts "  #{entity["type"]}#{@delim}#{entity["attributes"]["name"]}"
    end
    puts "[ ] End Results"

    puts "[+] Task Log:\n"
    puts response["task_log"]

    #puts "Full Response (JSON):"
    #puts response.to_json

  end

  ###
  ### XXX - rewrite this so it uses the API
  ###
  desc "load [Task] [Filename] [Option1=Value1#...#...]", "Load entities from a file and run task"
  def load(task_name,file,options=nil)

    lines = File.open(file,"r").readlines

    lines.each do |line|
      line.chomp!

      entity_type = line.split(@delim).first
      entity_name = line.split(@delim).last

      #puts "Entity type: #{entity_type}"
      #puts "Entity name: #{entity_name}"

      entity = {  :type => entity_type,
                  :attributes => { :name => entity_name} }

      payload = {
        :task => task_name,
        :entity => entity,
        #:options => [{:name => "max_length",
        #              :value => 8 }],
      }

      task_id = SecureRandom.uuid

      ###
      # XXX - Create the task
      ###
      task = TaskFactory.create_by_name(task_name)
      jid = task.class.perform_async task_id, entity, options, "file", nil

      puts "Created task #{task_id} for entity #{entity}"
    end
  end

end # end class

IntrigueCli.start
