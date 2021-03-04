module Intrigue
module Task
class BaseTask

  # include default helpers
  include Intrigue::Task::Generic
  include Intrigue::Task::Issue
  include Intrigue::Task::BinaryEdge
  include Intrigue::Task::Browser
  include Intrigue::Task::CloudProviders
  include Intrigue::Task::Data
  include Intrigue::Task::Dns
  include Intrigue::Task::Regex
  include Intrigue::Task::Services
  include Intrigue::Task::VulnCheck
  include Intrigue::Task::VulnDb
  include Intrigue::Task::Web
  include Intrigue::Task::WebContent
  include Intrigue::Task::WebAccount
  include Intrigue::Task::Whois
  include Intrigue::Task::TlsHandler

  include Sidekiq::Worker
  sidekiq_options :queue => "task", :backtrace => true

  def self.inherited(base)
    ::Intrigue::TaskFactory.register(base)
  end

  def perform(task_result_id)
    ### This method is used by a couple different TYPES...
    # normal tasks... which are simple, just run and exit
    # enrichment tasks.. which must notify when done, and will launch a machine!!!

    # Get the task result and fail if we can't
    @task_result = Intrigue::Core::Model::TaskResult.first(:id => task_result_id)

    # gracefully handle situations where the task result has gone missing
    # usually this is a deleted project
    return nil unless @task_result

    ###########################
    #  Setup the task result  #
    ###########################
    @task_result.task_name = self.class.metadata[:name]
    start_time = Time.now.getutc
    @task_result.timestamp_start = start_time

    ###
    ### Check santity
    ###
    @entity = @task_result.base_entity
    @project = @task_result.project
    options = @task_result.options

    # we must have these things to continue (if they're missing, fail)
    unless @task_result && @project && @entity
      _log_error "Unable to find task_result. Bailing." unless @task_result
      _log_error "Unable to find project. Bailing." unless @project
      _log_error "Unable to find entity. Bailing." unless @entity
      return 
    end

    ###
    ### Handle cancellation
    ###
    if @task_result.cancelled
      _log "Cancelled, returning without running!"
      return
    end
    
    ###
    ### Handle already finished or already started results with the e
    ### same name in the same scan. Check for existing "same" task results
    ### that havec already started or completed, and bail early 
    ### if that's the case
    ###
    return_early = false 
    if @task_result.scan_result
      our_task_result_name = @task_result.name
      
      # query existing results, limit to those that have been started
      existing_task_results = Intrigue::Core::Model::TaskResult.scope_by_project(@project.name).where({
        :name => "#{our_task_result_name}"}).exclude(:timestamp_start => nil)

      # good for debugging 
      _log "Got existing results for '#{our_task_result_name}': #{existing_task_results.map{|x| x.id }.join(", ")}"

      # if we've already completed another one, return eearly
      if existing_task_results.count > 1 && existing_task_results.exclude(:timestamp_end => nil).count > 1
      
        _log "This task has already been completed in this scan, returning w/o running!"
        return_early = true 
      
      # if we've already even started another one, return eearly
      elsif existing_task_results.count > 1 
      
        _log "This task is currently in progress in this scan, returning w/o running!"
        return_early = true 
      
      end
    end

    if return_early
      @task_result.complete = true
      @task_result.timestamp_end = Time.now.getutc
      @task_result.logger.save_changes
      @task_result.save_changes
      _log "Task returning early!"
      return 
    end

    # We need a flag to skip the actual setup, run, cleanup of the task if
    # the caller gave us something broken. We still want to get the final
    # task result back to the caller though (so no raise). Assume it's good,
    # and check input along the way.
    broken_input_flag = false

    ###################
    # Sanity Checking #
    ###################
    allowed_types = self.class.metadata[:allowed_types]

    # Check to make sure this task can receive an entity of this type
    unless allowed_types.include?(@entity.type_string) || allowed_types.include?("*")
      _log_error "Unable to call #{self.class.metadata[:name]} on entity: #{@entity} of type #{@entity.type_string}. allowed_types: #{allowed_types}"
      broken_input_flag = true
    end

    begin

      #####################################
      # Perform the setup -> run workflow #
      #####################################
      unless broken_input_flag
        # Setup creates the following objects:
        # @user_options - a hash of task options
        # @task_result - the final result to be passed back to the caller
        ###
        ### CALL SETUP
        ###
        if setup(task_result_id, @entity, options)
            _log "Starting task run at #{start_time}!"
            @task_result.save_changes # Save the task

            ###
            ## RUN IT - THE TASK'S MAGIC HAPPENS HRE
            ###
            run # Run the task, which will update @task_result

            end_time = Time.now.getutc
            _log "Task run finished at #{end_time}!"
        else
          _log_error "Task setup failed, bailing out w/o running!"
        end
      end
    
      ###
      ## FINALIZE ENRICHMENT
      ###
      # Now, if this is an enrichment type task, we want to mark our enrichemnt complete 
      # if it's true, we can set it and launch our followon-work!
      if Intrigue::TaskFactory.create_by_name(@task_result.task_name).class.metadata[:type] == "enrichment"
        
        ### NOW WE CAN SET ENRICHED!
        @entity.enriched = true 
  
        ### NOW WE CAN DECIDE SCOPE BASED ON COMPLETE ENTITY (unless we were already scoped in!)
        unless @entity.scoped
          @entity.set_scoped!(@entity.scoped?, "entity_scoping_rules") #always fall back to our entity-specific logic if there was no request
          #_log_good "POST-ENRICH AUTOMATED ENTITY SCOPE: #{@entity.scoped}"
        end
        @entity.save_changes 
        

        ###
        ## NOW, KICK OFF MACHINES for SCOPED ENTiTIES ONLY
        ###

        # technically socped shoudl handle but it doesnt
        if @entity.enriched && @entity.scoped? #&& !@entity.hidden 

          # MACHINE LAUNCH (ONLY IF WE ARE ATTACHED TO A MACHINE) 
          # if this is part of a scan and we're in depth
          if @task_result.scan_result && @task_result.depth > 0

            machine_name = @task_result.scan_result.machine
            @task_result.log "Launching machine #{machine_name} on #{@entity.name}"
            machine = Intrigue::MachineFactory.create_by_name(machine_name)

            unless machine
              raise "Unable to continue, missing machine: #{machine_name}!!!"
            end
            
            ## 
            ## Start the machine!
            ##
            machine.start(@entity, @task_result)

          else
            @task_result.log "No machine configured for #{@entity.name}!"
          end


          scan_result = @task_result.scan_result
          if scan_result
            scan_result.decrement_task_count

            #####################
            #   Call Handlers   #
            #####################

            ### Task Result Handlers
            if @task_result.handlers.count > 0
              _log "Launching Task Handlers!"
              @task_result.handle_attached
              @task_result.handlers_complete = true
            else
              _log "No task result handlers configured."
            end

            ### Scan Result Handlers
            if scan_result.handlers.count > 0
              # Check our incomplete task count on the scan to see if this is the last one
              if scan_result.incomplete_task_count <= 0
                _log "Last task standing, let's handle the scan!"
                scan_result.handle_attached
                # let's mark it complete if there's nothing else to do here.
                scan_result.handlers_complete = true
                scan_result.complete = true
                scan_result.save_changes
              end
            else
              _log "No scan result handlers configured."
            end
          end
        else 
          _log "Entity not scoped, no machine will be run."
        end 





      else
        _log "Not an enrichment task, skipping machine generation"
      end

      
    ensure
      begin

        ###
        ## CLEAN UP HERE. 
        ###

        @task_result.complete = true
        @task_result.timestamp_end = end_time
        @task_result.logger.save_changes
        @task_result.save_changes
        _log "Task complete. Ship it!"
      rescue Sequel::NoExistingObject => e
        puts "Failing to update task_result: #{task_result_id}"
      end
    end


  end

  #########################################################
  # These methods are used to perform work in several steps.
  # they should be overridden by individual tasks, but note that
  # individual tasks must always call super()
  #
  def setup(task_id, entity, user_options)

    # We need to parse options and make sure we're
    # allowed to accept these options. Compare to allowed_options.

    #
    # allowed options is formatted:
    #    [{:name => "count", :type => "Integer", :default => 1 }, ... ]
    #
    # user_options is formatted:
    #    [{"name" => "option name", "value" => "value"}, ...]

    allowed_options = self.class.metadata[:allowed_options]
    @user_options = []
    if user_options
      #_log "Got user options list: #{user_options}"
      # for each of the user-supplied options
      user_options.each do |user_option| # should be an array of hashes
        # go through the allowed options
        allowed_options.each do |allowed_option|
          # If we have a match of an allowed option & one of the user-specified options
          if "#{user_option["name"]}" == "#{allowed_option[:name]}"

            ### Match the user option against its specified regex
            if allowed_option[:regex] == "integer"
              #_log "Regex should match an integer"
              regex = _get_regex(:integer)
            elsif allowed_option[:regex] == "boolean"
              #_log "Regex should match a boolean"
              regex = _get_regex(:boolean)
            elsif allowed_option[:regex] == "alpha_numeric"
              #_log "Regex should match an alpha-numeric string"
              regex = _get_regex(:alpha_numeric)
            elsif allowed_option[:regex] == "alpha_numeric_list"
              #_log "Regex should match an alpha-numeric list"
              regex = _get_regex(:alpha_numeric_list)
            elsif allowed_option[:regex] == "numeric_list"
              #_log "Regex should match an alpha-numeric list"
              regex = _get_regex(:numeric_list)
            elsif allowed_option[:regex] == "filename"
              #_log "Regex should match a filename"
              regex = _get_regex(:filename)
            elsif allowed_option[:regex] == "ip_address"
              #_log "Regex should match an IP Address"
              regex = _get_regex(:ip_address)
            else
              _log_error "Unspecified regex for this option #{allowed_option[:name]}"
              _log_error "Unable to continue, failing!"
              return nil
            end

            # Run the regex
            unless regex.match "#{user_option["value"]}"
              _log_error "Regex didn't match"
              _log_error "Option #{user_option["name"]} does not match regex: #{regex.to_s} (#{user_option["value"]})!"
              _log_error "Regex didn't match, failing!"
              return nil
            end

            ###
            ### End Regex matching
            ###

            # We have an allowed option, with the right kind of value
            # ...Now set the correct type

            # So things like core-cli are parsing data as strings,
            # and are sending us all of our options as strings. Which sucks. We
            # have to do the explicit conversion to the right type if we want things to go
            # smoothly. I'm sure there's a better way to do this in ruby, but
            # i'm equally sure don't know what it is. We'll fail the task if
            # there's something we can't handle

            if allowed_option[:regex] == "integer"
              # convert to integer
              #_log "Converting #{user_option["name"]} to an integer"
              user_option["value"] = user_option["value"].to_i
            elsif allowed_option[:regex] == "boolean"
              # use our monkeypatched .to_bool method (see initializers)
              #_log "Converting #{user_option["name"]} to a bool"
              user_option["value"] = user_option["value"].to_bool if user_option["value"].kind_of? String
            end

            # Hurray, we can accept this value
            @user_options << { allowed_option[:name] => user_option["value"] }
          end
        end

      end
      _log "Options: #{@user_options}"
    else
      _log "No User options"
    end

  true
  end

  # This method is overridden
  def run
  end
  #
  #########################################################

  # Override this method if the task has external dependencies
  def check_external_dependencies
    true
  end

end
end
end
