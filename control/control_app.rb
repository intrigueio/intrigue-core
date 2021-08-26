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
        @config = config
        @logfile = config["logfile"]
        @app_hostname = config["app_hostname"]
        @app_protocol = config["app_protocol"]
        @app_key = config["app_key"]
        @handler = config["handler"]
        @max_priority = config["max_priority"]
        @min_priority = config["min_priority"]
        @platform_ingress = config["platform_ingress"]
        @load_global_entities = config["load_global_entities"]
        @core_dir = config["core_dir"]
        @engine_source = config["engine_source"]
        @sleep_interval = config["sleep_interval"]
        @max_seconds = config["max_seconds"]

        # initialize slack notifier
        Intrigue::ControlHelpers::set_notifier(config["slack_hook_url"])
        Intrigue::ControlHelpers::set_logfile(@logfile)
        
      end

      # the run method, this is where the magic happens
      def run

        _log "Starting control..."

        # first we load in gloabl entities
        _log "Loading global entities..."
        _load_global_entities

        while true
          # reset data
          instruction_data = nil
          bootstrap_data = nil
          collect_success = false

          # see if we need to process any commands from botmaster shpend
          _process_command

          # check if we just crash and try to recover
          # else we will grab the next collection from queue
          if _recover == true
            instruction_data, bootstrap_data = _load_backup_files
            next unless instruction_data && bootstrap_data
            collect_success = _process_collection(instruction_data, bootstrap_data, false)
          else
            # we're starting fresh so ensure we're clean
            _cleanup

            # get next instruction
            instruction_data, bootstrap_data = _get_collection_in_queue
            next unless instruction_data && bootstrap_data

            # write backup files in case we crash/reboot
            _log "Writing backup files for #{instruction_data["collection"]}!"
            _write_backup_files(instruction_data, bootstrap_data)

            # process collection
            collect_success = _process_collection(instruction_data, bootstrap_data, true)
          end

          
          # if collection was successful, send the finished project to s3
          if collect_success
            res_finished = _send_finished_project
            if res_finished == false
              # failed to finish, cleanup and restart
              _cleanup
            end
          else
            # collect failed, cleanup and move on
            _cleanup
          end

          # done with this round, on to the next!
          exit(0) # TODO: remove when finished
        end

      end
      
      ###
      # Main Methods
      ###
      # this method loads the global intel, if the configuration says to do so
      def _load_global_entities
        # don't load global intel if not configured
        if @load_global_entities == false
          return
        end

        counter = 3 # counter for attemps to try to get global entities
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/entities/global/entities?key=#{@app_key}"
        while counter > 0
          begin
            _log "Making attempt number #{counter} for global entities"
            response = http_request(:get, uri, nil, {}, nil, true, 60)
    
            # handle missing data
            if response && response.body.length > 0
              _log "Got the data. Loading it in..."
              j = JSON.parse(response.body)
              Intrigue::Core::Model::GlobalEntity.load_global_namespace(j)
              return
            else
              _log "unable to get global entities intel, retrying..."
            end
          rescue JSON::ParserError
            _log_error "Unable to parse global entities json, retrying..."
          end
          counter = counter - 1
        end
    
        # no more attempts left, raise and die
        raise "Unable to load global entities. Cannot continue!"
      end

      def _get_collection_in_queue
        _log "Getting next collection in queue..."
        instruction_data = _get_queued_instruction
        if !instruction_data
          _log_error "Failed to get queued instruction! Cannot continue!"
          return false
        end
        # pull out some info
        collection_name = instruction_data["collection"]
        collection_run_uuid = instruction_data["uuid"] || instruction_data["id"]
        cr_session_token = instruction_data["session_token"]

        # get boostrap information for collection
        _log "Getting bootstrap information for collection: #{collection_name}"
        bootstrap_data = _get_bootstrap_data("#{collection_name}", collection_run_uuid, cr_session_token)
        if !bootstrap_data
          _log_error "Failed to get bootstrap data for collection: #{collection_name}! Moving on."
          return false
        end

        bootstrap_data = bootstrap_data.merge({"collection_run_uuid" => collection_run_uuid, "session_token" => cr_session_token})

        return instruction_data, bootstrap_data
      end
      
      # this method obtains the next collection from the queue
      def _get_queued_instruction
        instruction_data = {}
        until instruction_data && instruction_data["empty"] == false
          #_log "Attempting to get an instruction from the queue!"

          begin
            uri = "#{@app_protocol}://#{@app_hostname}/api/system/scheduler/request?key=#{@app_key}&min_priority=#{@min_priority}&max_priority=#{@max_priority}"
            #_log "Making request for instructions on with min_priority: #{@min_priority} and max_priority: #{@max_priority} queue."
            
            response = http_request(:get, uri, nil, {}, nil, true, 60) 
            
            if response 
              _log "Got instruction: #{response.body}" # DEBUG line
              instruction_data = JSON.parse(response.body)
              return instruction_data
            end
      
          rescue JSON::ParserError => e
            _log_error "Can't parse response."
          end

          wait_time = rand(100)
          puts "Obtaining bootstrap information failed! Sleeping... #{wait_time} before new attempt"
          sleep wait_time 
  
        end
    
        false
      end

      # this method obtains the boostrap information for a given queue
      def _get_bootstrap_data(collection_name, collection_run_uuid, cr_session_token)
        counter = 3 # counter for attemps to try

        while counter > 0 
          uri = "#{@app_protocol}://#{@app_hostname}/api/system/collections/#{collection_name}/bootstrap?key=#{@app_key}"
          begin
            #_log "Making attempt #{counter} for bootstrap"
            headers = {
              "COLLECTION_RUN_SESSION_TOKEN" => "#{cr_session_token}", 
              "ENGINE_API_KEY" => "#{@app_key}"
            }
            response = http_request(:get, uri, nil, headers, nil, true, 60)
      
            if response && response.body.length > 0
              j = JSON.parse(response.body)
              return j
            end
      
          rescue JSON::ParserError => e
            _log_error "Unable to parse bootstrap json. Retrying..."
          end
          counter = counter - 1
        end
        return false
      end

      # this function processes a collection, meaning we bootstrap if necessary and wait for the tasks to be completed
      def _process_collection(instruction_data, bootstrap_data, should_bootstrap)
        
        # if we should bootstrap system, do so
        if should_bootstrap
          Dir.chdir @core_dir do
            # merge in our uuid so it can be tracked with the project
            bootstrap_system(bootstrap_data)
          end
        end

        # wait for all tasks to be finished
        done = false
        iteration = 1
        until done
          # hold tight, now we're running
          sleep @sleep_interval

          # in case we get a command from our botmaster shpend
          comm = _process_command
          if comm == "restart"
            #bot master wants us to restart.
            return false
          end

          # determine how we're doing after a nap
          task_count_left = _tasks_left
          seconds_elapsed = iteration * @sleep_interval
          done = (iteration > 12 && task_count_left <= 0 ) || (seconds_elapsed > @max_seconds)
        
          # print some output every 5th iteration
          if iteration % 5 == 0 || done
            log_message =  " Collection: #{collection_name}"
            log_message << " | Seconds elapsed: #{seconds_elapsed}" 
            log_message << " | Tasks left: #{task_count_left}"
            log_message << " | Done!" if done
            _log log_message

            # let C&C know we're alive
            _send_heartbeat(collection_run_uuid, cr_session_token)
          end
          
          iteration += 1
        end
        return done
      end

      def _send_finished_project(instruction_data, bootstrap_data, seconds_elapsed)
        # don't send finished project if we're not going to ingress
        if @platform_ingress == false
          return true
        end
        
        # pull out some info
        collection_name = instruction_data["collection"]
        collection_run_uuid = instruction_data["uuid"] || instruction_data["id"]
        cr_session_token = instruction_data["session_token"]
        
        project = Intrigue::Core::Model::Project.first(:name => "#{collection_name}")
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
          _clear_queues
    
          # finished status
          _log "Sending 'finished' status"
          _set_status "finished", collection_run_uuid, {
            "seconds_elapsed" => "#{seconds_elapsed}",
            "statistics" => stats_hash,
            "entity_count" => "#{entity_count}"
          }, cr_session_token
    
          # okay, lets send it up
          _log "Running handlers"
          _run_handlers bootstrap_data
    
          _log "Nuking the project #{project.name}"
          project&.delete!

          _log "Cleaning logfiles"
          _clear_logfiles

          _log_notifier "All done. Finished collection #{collection_name}, duration: #{seconds_elapsed} seconds."
          return true
        else
          _log_error "Unable to find project #{collection_name}, it's gone missing!!"
          return false
        end
      end
      
      def _process_command
        begin
          lines = File.readlines("#{@core_dir}/tmp/commands.txt")
          command = lines.first&.strip
          success = false
      
          if command == "pause"
            puts "Pausing control."
            while true
              sleep 5
              lines2 = File.readlines("#{@core_dir}/tmp/commands.txt")
              command2 = lines2.first&.strip
              if command2 == "unpause"
                puts "UN-Pausing control."
                File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines2.drop(1)) }
                break
              end
            end
            success = true
          end
        
          if command == "unpause"
            puts "Got unpause command but we're not paused."
            success = true
          end
      
          if command == "cleanup"
            puts "Got cleanup command"
            _cleanup
            success = true
          end
          
          if command == "restart"
            puts "Got restart command"
            success = true
          end

          # if command executed successfully, remove it from list 
          if success
            File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines.drop(1)) }
          else
            File.open("#{@core_dir}/tmp/commands.txt", 'w') {|file| file.puts(lines) }
          end
        rescue Errno::ENOENT
          return
        end
      
      end # process command

      def _set_status(s, uuid, details={}, cr_session_token)
        # if we don't do ingress, we also don't send a status back to platform
        if @platform_ingress == false
          return
        end
        
        _log "Sending status #{s} for #{uuid}"
        message = {"status" => s}.merge({ "engine" => @hostname, "ip_address" => @ip_address , "source" => "#{@engine_source}"}).merge(details)
        uri = "#{@app_protocol}://#{@app_hostname}/api/system/scheduler/runs/#{uuid}?key=#{@app_key}"
        headers = {
            "COLLECTION_RUN_SESSION_TOKEN" => "#{cr_session_token}", 
            "ENGINE_API_KEY" => "#{@app_key}"
          }
        response = http_request(:post, uri, nil, headers, message, true, 60)
        return response
      end

      def _send_heartbeat(collection_run_uuid, cr_session_token)
        status_res = _set_status "heartbeat", collection_run_uuid, {}, cr_session_token
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
      
      def _recover
        if _backup_instruction_file_exists? && _backup_bootstrap_file_exists?
          _log "Found backup instruction and bootstrap files, attempting recovery."
          instruction_data, bootstrap_data = _load_backup_files 
          # ok backup files exist, we came back from a crash. pull out data
          collection_name = instruction_data["collection"]
          collection_run_uuid = instruction_data["uuid"] || instruction_data["id"]
          cr_session_token = instruction_data["session_token"]

          # send a heartbeat and fail if we don't get a valid heartbeat response
          res = _send_heartbeat(collection_run_uuid, cr_session_token)
          if res == false
            _log "Heartbeat for recovered collection failed. Recovery failed"
            return false
          end

          _log "Recovery successful!"
          return true
        end
        return false
      end

      def _tasks_left
        count = 0 # start at 0
        # get the currently running processes
        ps = Sidekiq::ProcessSet.new
        ps.each do |process|
          count += process['busy']
        end
    
        count += Sidekiq::Stats.new.enqueued
        return count
      end

      def _clear_queues
        until _tasks_left <= 0
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

      def _clear_logfiles
        File.open(@log_to_file, 'w') {|file| file.truncate(0) }
      end

      def _clear_projects
        projects = Intrigue::Core::Model::Project.all
        projects.each do |p|
          p.cancelled = true
          p.save
          p.delete!
        end
      end

      def _cleanup
        _clear_queues
        _clear_projects
        _clean_backup_files
        _clear_logfiles
      end

      ###
      # Helper Methods
      ###

      def _backup_instruction_file_exists?
        File.exist?("#{@core_dir}/tmp/instruction.backup.json")
      end
    
      def _backup_bootstrap_file_exists?
        File.exist?("#{@core_dir}/tmp/bootstrap.backup.json")
      end
      
      def _clean_backup_files
        File.delete("#{@core_dir}/tmp/instruction.backup.json") if _backup_instruction_file_exists?
        File.delete("#{@core_dir}/tmp/bootstrap.backup.json") if _backup_bootstrap_file_exists?
      end
    
      def _write_backup_files(instruction_data, bootstrap_data)
        return false unless instruction_data && bootstrap_data
        File.open("#{@core_dir}/tmp/instruction.backup.json","w"){|f| f.puts(JSON.pretty_generate(instruction_data)) }
        File.open("#{@core_dir}/tmp/bootstrap.backup.json","w"){|f| f.puts(JSON.pretty_generate(bootstrap_data)) }
      end

      def _load_backup_files
        # load the file 
        instruction_data = JSON.parse(File.read("#{@core_dir}/tmp/instruction.backup.json"))
        bootstrap_data = JSON.parse(File.read("#{@core_dir}/tmp/bootstrap.backup.json"))
    
        return instruction_data, bootstrap_data
      end


    end # intrigue class end
  end
end