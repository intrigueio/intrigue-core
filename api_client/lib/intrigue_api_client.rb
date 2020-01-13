require 'rubygems'
require 'json'
require 'rest_client'

###
### SAMPLE USAGE
###

=begin
x =  Intrigue.new

  #
  # Create an entity hash, must have a :type key
  # and (in the case of most tasks)  a :attributes key
  # with a hash containing a :name key (as shown below)
  #
  entity = {
    :type => "String",
    :attributes => { :name => "intrigue.io"}
  }

  #
  # Create a list of options (this can be empty)
  #
  options_list = [
    { :name => "resolver", :value => "8.8.8.8" }
  ]

x.start "example", entity_hash, options_list
id  = x.start "search_bing", entity_hash, options_list
#puts x._get_log id
#puts x._get_result id

=end

class IntrigueApi

    def self.version
      "1.5.0"
    end

    def initialize(uri="http://127.0.0.1:7777",key="")
      @intrigue_basedir = File.dirname(__FILE__)
      @server_uri = uri
    end

    # List all tasks
    def list
      _get_json_result "tasks.json"
    end

    # Show detailed about a task
    def info(task_name)
      _get_json_result "tasks/#{task_name}.json"
    end

    # create a new project
    def create_project(project_name)
      RestClient.post "#{@server_uri}/project", { "project" => project_name }
    end

    def background(project_name,task_name,entity_hash,depth=1,options_list=nil,handler_list=nil, machine_name=nil, auto_enrich=true)
      # Construct the request
      task_id = _start_and_background(project_name,task_name,entity_hash,depth,options_list,handler_list, machine_name, auto_enrich)
    end


    # Start a task and wait for the result
    def start(project_name,task_name,entity_hash,depth=1,options_list=nil,handler_list=nil, machine_name=nil, auto_enrich=true)

      # Construct the request
      task_id = _start_and_background(project_name,task_name,entity_hash,depth,options_list,handler_list, machine_name, auto_enrich)

      if task_id == "" # technically a nil is returned , but becomes an empty string
        #puts "[-] Task not started. Unknown Error. Exiting"
        raise "Problem getting result"
        return nil
      else
        #puts "[+] Got Task ID: #{task_id}"
      end

      ### XXX - wait to collect the response
      complete = false
      until complete
        sleep 1
        begin

          check_uri = "#{@server_uri}/#{project_name}/results/#{task_id}/complete"
          #puts "[+] Checking: #{check_uri}"
          response = RestClient.get check_uri
          complete = true if response == "true"
          #return nil if response == ""

        rescue URI::InvalidURIError => e
          #puts "[-] Invalid URI: #{check_uri}"
          return nil
        end
      end

      ### Get the response
      response = _get_json_result "#{project_name}/results/#{task_id}.json"

    response
    end


    private
    # start_and_background - start and background a task
    #
    # project_name - must exist as a valid project_name
    # task_name - must exist as a valid task name
    # entity_hash - symbol-based hash representing an entity: {
    #  :type => "String"
    #  :attributes => { :name => "intrigue.io"}
    # }
    # options_list - list of options:  [
    #   {:name => "resolver", :value => "8.8.8.8" }
    # ]
    def _start_and_background(project_name,task_name,entity_hash,depth,options_list,handler_list, machine_name, auto_enrich)

      payload = {
        "project_name" => project_name,
        "task" => task_name,
        "options" => options_list,
        "handlers" => handler_list,
        "entity" => entity_hash,
        "depth" => depth,
        "machine_name" => machine_name,
        "auto_enrich" => auto_enrich
      }

      ### Send to the server
      task_id = RestClient.post "#{@server_uri}/#{project_name}/results",
        payload.to_json, :content_type => "application/json"

      if task_id == "" # technically a nil is returned , but becomes an empty string
        #puts "[-] Task not started. Unknown Error. Exiting"
        #raise "Problem getting result"
        return nil
      end

    task_id
    end

    def _get_log(task_id)
      log = _get_json_result "#{project_name}/results/#{task_id}/log"
    end

    def _get_result(task_id)
      begin
        result = _get_json_result "#{project_name}/results/#{task_id}.json"
      rescue JSON::ParserError => e
        response = nil
      end
    result
    end

    def _get_json_result(path)
      begin
        result = JSON.parse(RestClient.get "#{@server_uri}/#{path}")
      rescue JSON::ParserError => e
        #puts "Error: #{e}"
      rescue RestClient::InternalServerError => e
        #puts "Error: #{e}"
      end
    result
    end


end
