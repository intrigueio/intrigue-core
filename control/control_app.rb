require './control/control_helper.rb'
require './core.rb'

include Intrigue::ControlHelpers
include Intrigue::Core::System
include Intrigue::Task::Web

module Intrigue
  module Control
    class Intrigueio
      
      # initialize control
      def initialize(config)

        # Set come configuration params
        @hostname = `hostname`
        @ip_address = `ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

        # platform configuration
        @logfile = config["logfile"]
        @app_hostname = config["app_hostname"]
        @app_protocol = config["app_protocol"]
        @app_key = config["app_key"]
        @handler = config["handler"]
        @max_priority = config["max_priority"]
        @min_priority = config["min_priority"]

        # environment configuration
        @platform_ingress = config["platform_ingress"]
        @load_global_entities = config["load_global_entities"]
        @core_dir = config["core_dir"]
        @engine_source = config["engine_source"]
        @sleep_interval = config["sleep_interval"]
        @max_seconds = config["max_seconds"]

        # collection specific info
        @start_time = nil
        @collection_name = nil
        @collection_run_uuid = nil
        @cr_session_token = nil
        @instruction_data = nil
        @bootstrap_data = nil

        # initialize slack notifier
        Intrigue::ControlHelpers::set_notifier(config["slack_hook_url"])
        Intrigue::ControlHelpers::set_logfile(@logfile)

        # cleanup in case we're not clean
        cleanup

        # load global intel
        _load_global_entities

      end

      # the run method, this is where the magic happens
      def run
        # ensure we're clean
        cleanup

        instruction_data = _get_queued_instruction
        return false unless instruction_data && instruction_data["collection"] && instruction_data["session_token"]

        bootstrap_data = _get_bootstrap_data(instruction_data["collection"], instruction_data["session_token"])
        return false unless bootstrap_data

        # bootstrap the system
        Dir.chdir @core_dir do
          # merge in our uuid so it can be tracked with the project
          bootstrap_system(bootstrap_data)
        end

        # set project variables
        @instruction_data = instruction_data
        @bootstrap_data = bootstrap_data
        @collection_name = instruction_data["collection"]
        @collection_run_uuid = instruction_data["uuid"] || instruction_data["id"]
        @cr_session_token = instruction_data["session_token"]
        @start_time = Time.now

        # set status to started
        _set_status "started"

        # return collection name to caller
        return @collection_name

      end

      # method to get current progress
      def get_progress
        log_message =  "Collection: #{@collection_name}"
        log_message << " | Seconds elapsed: #{seconds_elapsed}" 
        log_message << " | Tasks left: #{tasks_left}"
        return log_message
      end

      # send results to platform
      def send_finished_project
        # don't send finished project if we're not going to ingress
        if @platform_ingress == false
          return true
        end
        
        _log "Uploading project results."
        project = Intrigue::Core::Model::Project.first(:name => "#{@collection_name}")
        if project
          entity_count = project.entities.count
          issue_count = project.issues.count 
          seed_count = project.seeds.count 
          task_result_count = project.task_results.count 
    
          ###
          ### Craft statistics that we can send back 
          ###
          stats_hash = {
            "entity_count" => entity_count,
            "issue_count" => issue_count,
            "seed_count" => seed_count,
            "task_result_count" => task_result_count
          }
    
          _log "Cancelling completed project: #{project.name}"
          project.cancelled = true
          project.save

          _log "Clearing queues just in case"
          clear_queues
    
          # finished status
          _log "Sending 'finished' status"
          _set_status "finished", {
            "seconds_elapsed" => "#{seconds_elapsed}",
            "statistics" => stats_hash,
            "entity_count" => "#{entity_count}"
          }
    
          # okay, lets send it up
          _log "Running handlers"
          _run_handlers @bootstrap_data
    
          _log "Nuking the project #{project.name}"
          project&.delete!

          _log "Cleaning logfiles"
          _clear_logfiles

          _log_notifier "All done. Finished collection #{@collection_name}, duration: #{seconds_elapsed} seconds."
          return true
        else
          _log_error "Unable to find project #{@collection_name}, it's gone missing!!"
          return false
        end
      end

      # tell platform we're still alive
      def send_heartbeat
        status_res = _set_status "heartbeat", {}
        return false unless status_res
        if status_res.response_code == 400
          # request failed so our heartbeat failed
          return false
        end
        begin
          json_res = JSON.parse(status_res.body_utf8)
          if json_res["success"] == false
            return false
          end
        rescue JSON::ParserError
          return false
        end

        # i guess heartbeat worked
        return true
      end

      def tasks_left
        count = 0 # start at 0
        # get the currently running processes
        ps = Sidekiq::ProcessSet.new
        ps.each do |process|
          count += process['busy']
        end
    
        count += Sidekiq::Stats.new.enqueued
        return count
      end

      def seconds_elapsed
        Time.now - @start_time
      end

      def clear_queues
        until tasks_left <= 0
          _log "Clearing queues!"
          queues = ["task_enrichment","task_browser","task_scan", "task_autoscheduled", "task_spider", "task", "app", "graph"]
          queues.each do |q|
            _log "Clearing queue #{q}"
            Sidekiq::Queue.new(q).clear
          end
          Sidekiq::RetrySet.new.clear
          Sidekiq::ScheduledSet.new.clear
          # wait a bit before repeating
          sleep 5
        end
      end

      def cleanup
        clear_queues
        _clear_projects
        _clear_project_vars
      end
      
      private
      
      # this method loads the global intel, if the configuration says to do so
      def _load_global_entities
        # don't load global intel if not configured
        if @load_global_entities == false || File.exist?("#{@core_dir}/tmp/.global_entities_loaded")
          return
        end

        # load global entities
        _log "Loading global entities..."
        counter = 3 # counter for attemps to try to get global entities
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/entities/global/entities?key=#{@app_key}"
        while counter.positive?
          begin
            response = http_request(:get, uri, nil, {}, nil, true, 60)
            # handle missing data
            if response && response.body.length > 0
              j = JSON.parse(response.body)
              Intrigue::Core::Model::GlobalEntity.load_global_namespace(j)
              _log_ok "Global entities successfully loaded."
              File.write("#{@core_dir}/tmp/.global_entities_loaded", "")
              return
            else
              _log "Got invalid response for global entities, retrying..."
            end
          rescue JSON::ParserError
            _log_error "Unable to parse global entities json, retrying..."
          end
          counter -= 1
        end
    
        # no more attempts left, raise and die
        raise "Unable to load global entities. Cannot continue!"
      end
      
      # this method obtains the next collection from the queue
      def _get_queued_instruction
        _log "Getting instructions for next queued collection."
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/scheduler/request?key=#{@app_key}&min_priority=#{@min_priority}&max_priority=#{@max_priority}"
        
        # will try up to 10 times to get a new instruction before failing
        counter = 10
        while counter.positive?
          begin
            #_log "Making request for instructions on with min_priority: #{@min_priority} and max_priority: #{@max_priority} queue."
            response = http_request(:get, uri, nil, {}, nil, true, 60) 
            if response 
              #_log "Got instruction: #{response.body}" # DEBUG line
              instruction_data = JSON.parse(response.body)
              return instruction_data
            else
              _log_error "Failed to retrieve queued instruction, retrying."
              counter -= 1
            end
          rescue JSON::ParserError
            _log_error "Failed to parse queued instruction json, retrying."
            counter -= 1
          end
        end

        _log_error "Failed to get queued instruction after 10 tries. Giving up."
        return false
      end

      # this method obtains the boostrap information for a given queue
      def _get_bootstrap_data(collection_name, cr_session_token)
        _log "Getting bootstrap information for collection: #{collection_name}"
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/collections/#{collection_name}/bootstrap?key=#{@app_key}"
        
        counter = 10
        while counter.positive?
          begin
            # _log "Making attempt #{counter} for bootstrap"
            headers = {
              "COLLECTION_RUN_SESSION_TOKEN" => "#{cr_session_token}", 
              "ENGINE_API_KEY" => "#{@app_key}"
            }
            response = http_request(:get, uri, nil, headers, nil, true, 60)
            if response && response.body.length > 0
              j = JSON.parse(response.body)
              return j
            else
              _log_error "Failed to retrieve bootstrap information for collection #{collection_name} instruction, retrying."
              counter -= 1
            end
          rescue JSON::ParserError
            _log_error "Failed to parse bootstrap information json, retrying."
            counter -= 1
          end
        end
        
        _log_error "Failed to get bootstrap information for collection #{collection_name} after 10 tries. Giving up."
        return false
      end

      def _set_status(s, details={})
        # if we don't do ingress, we also don't send a status back to platform
        if @platform_ingress == false
          return
        end
        
        _log "Sending status #{s} for #{@collection_name}"
        message = {"status" => s}.merge({ "engine" => @hostname, "ip_address" => @ip_address , "source" => "#{@engine_source}"}).merge(details)
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/scheduler/runs/#{@collection_run_uuid}?key=#{@app_key}"
        headers = {
            "COLLECTION_RUN_SESSION_TOKEN" => "#{@cr_session_token}", 
            "ENGINE_API_KEY" => "#{@app_key}"
          }
        response = http_request(:post, uri, nil, headers, message, true, 60)
        return response
      end

      def _clear_projects
        projects = Intrigue::Core::Model::Project.all
        projects.each do |p|
          p.cancelled = true
          p.save
          p.delete!
        end
      end

      def _clear_project_vars
        @collection_name = nil
        @start_time = nil
        @collection_run_uuid = nil
        @cr_session_token = nil
        @instruction_data = nil
        @bootstrap_data = nil

      end

    end # intrigue class end
  end
end