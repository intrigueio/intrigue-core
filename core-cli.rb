#!/usr/bin/env ruby
require 'thor'
require 'json'
require 'rest-client'
require 'intrigue'

require 'pry' #DEBUG

class CoreCli < Thor

  def initialize(*args)
    super
    $intrigue_basedir = File.dirname(__FILE__)
    @server_uri = "http://127.0.0.1:7777/v1"
    @sidekiq_uri = "http://127.0.0.1:7777/sidekiq"
    @delim = "#"

    # Connect to Intrigue API
    @x = Intrigue.new
  end

  desc "stats", "Get queue stats"
  def stats
    stats_hash = JSON.parse(RestClient.get("#{@sidekiq_uri}/stats"))
    puts "Sidkiq: #{stats_hash["sidekiq"]}"
    puts "Redis: #{stats_hash["redis"]}"
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


  desc "scan [Type#Entity] [Depth]", "Start a recursive scan. Returns the result"
  def scan(entity,depth=3,options=nil)
    entity_hash = _parse_entity entity

    # create an array of results so we can shortcut
    # anything we already know (and not repeat work) during a scan
    $results = {}

    _recurse entity_hash, depth.to_i

    # Print results
    puts "Results:"
    $results.each do |key,value|
      puts "#{key}:"
      puts "#{value["entities"].map{|x| "  #{x["type"]} #{x["attributes"]["name"]}"}.join("\n")}"
    end
  end


  desc "background [Task] [Type#Entity] [Option1=Value1#...#...]", "Start and background a single task. Returns the ID"
  def background(task_name,entity,options=nil)

    entity_hash = _parse_entity entity
    options_list = _parse_options options

    ### Construct the request
    task_id = _background(task_name,entity_hash,options_list)

    if task_id == "" # technically a nil is returned , but becomes an empty string
      puts "[-] Task not started. Unknown Error. Exiting"
      return
    end

  puts "[+] Started task: #{task_id}"
  end



  desc "single [Task] [Type#Entity] [Option1=Value1#...#...]", "Start a single task. Returns the result"
  def single(task_name,entity,options=nil)

    entity_hash = _parse_entity entity
    options_list = _parse_options options

    ### Construct the request
    task_id = _background(task_name,entity_hash,options_list)
    puts "[+] Started task: #{task_id}"


    if task_id == "" # technically a nil is returned , but becomes an empty string
      puts "[-] Task not started. Unknown Error. Exiting."
      return
    end

    ### XXX - wait for the the response
    complete = false
    until complete
      sleep 1
      begin
        uri = "#{@server_uri}/task_runs/#{task_id}/complete"
        complete = true if(RestClient.get(uri) == "true")
      rescue URI::InvalidURIError => e
        puts "[-] Invalid URI: #{uri}"
        return
      end
    end

    puts "[+] Task complete!"

    ### Get the response
    puts "[+] Start Results"
    begin
      response = JSON.parse(RestClient.get "#{@server_uri}/task_runs/#{task_id}.json")
      response["entities"].each do |entity|
        puts "  [x] #{entity["type"]}#{@delim}#{entity["attributes"]["name"]}"
      end
    rescue Exception => e
      puts "[-] Error fetching and parsing response"
    end

    puts "[+] End Results"
    puts "[+] Task Log:\n"
    puts response["task_log"]
  end

  ###
  ### XXX - rewrite this so it uses the API
  ###
  desc "load [Task] [File] [Option1=Value1#...#...]", "Load entities from a file and run task on each of them"
  def load(task_name,filename,options_string=nil)

    # Load in the main core file for direct access to TaskFactory and the Tasks
    # This makes this super speedy.
    require_relative 'core'

    lines = File.open(filename,"r").readlines

    lines.each do |line|
      line.chomp!

      entity = _parse_entity line
      options = _parse_options options_string

      payload = {
        "task" => task_name,
        "entity" => entity,
        "options" => options,
      }

      task_id = SecureRandom.uuid

      # XXX - Create the task
      task = TaskFactory.create_by_name(task_name)
      jid = task.class.perform_async task_id, entity, options, ["csv_file", "json_file"], nil

      puts "Created task #{task_id} for entity #{entity}"
    end
  end

private

  ###
  ### Main "workflow" function
  ###
  def _recurse(entity, depth)

    # Check for bottom of recursion
    return if depth <= 0

    # Check for prohibited entity name
    if entity["attributes"]
      return if is_prohibited entity
    end

    if entity["type"] == "IpAddress"
      ### DNS Reverse Lookup
      _start_task "dns_lookup_reverse",entity,depth
      ### Whois
      _start_task "whois",entity,depth
      ### Shodan
      #_start_task "search_shodan",entity,depth
      ### Scan
      _start_task "nmap_scan",entity,depth
      ### Geolocate
      #_start_task "geolocate_host",entity,depth
    elsif  entity["type"] == "NetBlock"
      ### Masscan
      _start_task "masscan_scan",entity,depth
    elsif entity["type"] == "DnsRecord"
      ### DNS Forward Lookup
      _start_task "dns_lookup_forward",entity,depth
      ### DNS Subdomain Bruteforce
      _start_task "dns_brute_sub",entity,depth,[{"name" => "use_file", "value" => "false"}]
    elsif entity["type"] == "Uri"
      ### Get SSLCert
      _start_task "uri_gather_ssl_certificate",entity,depth
      ### Gather links
      _start_task "uri_gather_and_analyze_links",entity,depth
      ### Dirbuster
      _start_task "uri_dirbuster",entity,depth
      ## screenshot
      _start_task "uri_screenshot",entity,depth
      ### spider
      _start_task "uri_spider",entity,depth
    elsif entity["type"] == "String"
      # Brute TLD
      _start_task "dns_brute_tld",entity,depth
    else
      puts "UNHANDLED: #{entity["type"]} #{entity["attributes"]["name"]}"
      return
    end
  end

  def _start_task(task_name,entity,depth,options=[])
    puts "Calling #{task_name} on #{entity} with options #{options} at depth #{depth}"

    # and run it
    result = @x.start task_name, entity, options

    # XXX - Store the results for later lookup, avoid duplication (which should save a ton of time)
    key = "#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"
    if $results[key]
      puts "ALREADY FOUND: #{$results[key]["entity"]["attributes"]["name"]}"

      ###
      ### TODO find entity and link
      ###
      #old_entity = Neography::Node.find ....
      #node.outgoing(:child) << old_entity

      return
    else
      $results["#{task_name}_#{entity["type"]}_#{entity["attributes"]["name"]}"] = result
    end

    # Get the results and iterate
    result['entities'].each do |result|
      puts "NEW ENTITY: #{result["type"]} #{result["attributes"]["name"]}"

      # create a new node
      #this = Neography::Node.create(
      #  type: y["type"],
      #  name: y["attributes"]["name"],
      #  task_log: y["task_log"] )
      # store it on the current entity
      #node.outgoing(:child) << this

      # recurse!
      _recurse(result, depth-1)
    end

  end

  # List of prohibited entities - returns true or false
  def is_prohibited entity

    #puts "Checking is_prohibited #{entity}"

    if entity["type"] == "NetBlock"
      cidr = entity["attributes"]["name"].split("/").last.to_i
      return true unless cidr >= 22
    else
      return true if (  entity["attributes"]["name"] =~ /google/             ||
                        entity["attributes"]["name"] =~ /g.co/               ||
                        entity["attributes"]["name"] =~ /goo.gl/             ||
                        entity["attributes"]["name"] =~ /android/            ||
                        entity["attributes"]["name"] =~ /urchin/             ||
                        entity["attributes"]["name"] =~ /youtube/            ||
                        entity["attributes"]["name"] =~ /schema.org/         ||
                        entity["attributes"]["description"] =~ /schema.org/  ||
                        entity["attributes"]["name"] =~ /microsoft.com/      ||
                        #entity["attributes"]["name"] =~ /yahoo.com/          ||
                        entity["attributes"]["name"] =~ /facebook.com/       ||
                        entity["attributes"]["name"] =~ /cloudfront.net/     ||
                        entity["attributes"]["name"] =~ /twitter.com/        ||
                        entity["attributes"]["name"] =~ /w3.org/             ||
                        entity["attributes"]["name"] =~ /akamai/             ||
                        entity["attributes"]["name"] =~ /akamaitechnologies/ ||
                        entity["attributes"]["name"] =~ /amazonaws/          ||
                        entity["attributes"]["name"] == "feeds2.feedburner.com")
    end
  false
  end

  # parse out entity from the cli
  def _parse_entity(entity)
    entity_type = entity.split(@delim).first
    entity_name = entity.split(@delim).last

    entity_hash = {
      "type" => entity_type,
      "attributes" => { "name" => entity_name}
    }
  entity_hash
  end

  # Parse out options from cli
  def _parse_options(options)

      return [] unless options

      options_list = options.split(@delim).map do |option|
        { "name" => option.split("=").first, "value" => option.split("=").last }
      end
  options_list
  end

  def _background(task_name,entity_hash,options_list=[])

    payload = {
      "task" => task_name,
      "options" => options_list,
      "entity" => entity_hash
    }

    ###
    ### Send to the server
    ###

    task_id = RestClient.post "#{@server_uri}/task_runs", payload.to_json, "content_type" => "application/json"

    task_id
  end

end # end class

CoreCli.start
