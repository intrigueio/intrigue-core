module Intrigue
module Task
class BaseTask

  include Sidekiq::Worker
  sidekiq_options queue: "task", backtrace: true

  # include default helpers
  include Intrigue::Task::AwsHelper
  include Intrigue::Task::Popen
  include Intrigue::Task::Generic
  include Intrigue::Task::BinaryEdge
  include Intrigue::Task::Browser
  include Intrigue::Task::Certificate
  include Intrigue::Task::CloudProviders
  include Intrigue::Task::Data
  include Intrigue::Task::Dns
  include Intrigue::Task::Gitlab
  include Intrigue::Task::Github
  include Intrigue::Task::Ident
  include Intrigue::Task::Issue
  include Intrigue::Task::Regex
  include Intrigue::Task::Serp
  include Intrigue::Task::Services
  include Intrigue::Task::Socket
  include Intrigue::Task::VulnCheck
  include Intrigue::Task::VulnDb
  include Intrigue::Task::Web
  include Intrigue::Task::WebContent
  include Intrigue::Task::WebAccount
  include Intrigue::Task::Whois
  include Intrigue::Task::Geolocation

  def self.inherited(base)
    ::Intrigue::TaskFactory.register(base)
  end

  ### This method is used by a couple different TYPES...
  #  - normal tasks... which are simple, just run and exit
  #  - enrichment tasks.. which must notify when done, and will launch a workflow!!!
  #  - checks.. which just need to return a result or false
  #
  def perform(task_result_id)
    start_time = Time.now.getutc.iso8601

    # Get the task result and fail if we can't
    @task_result = Intrigue::Core::Model::TaskResult.first(:id => task_result_id)

    # While it would be sensible to raise an error here, because we currently
    # dont have a limit on retries, this leads to task results for deleted projects
    # getting stuck in 'zombie' mode, where they keep retrying and failing.
    if @task_result && @task_result.project
      puts "[#{start_time}] Running task result #{@task_result.name} in project: #{@task_result.project.name}"
    else  #raise InvalidTaskConfigurationError, "Missing task result?"
      puts "[#{start_time}] WARNING! Unable to run missing task result: #{task_result_id}, failing!"
      return nil
    end

    ###########################
    #  Setup the task result  #
    ###########################
    @task_result.task_name = self.class.metadata[:name]
    @task_result.timestamp_start = start_time

    ###
    ### Alias things to make task access easier
    ###
    @entity = @task_result.base_entity
    @project = @task_result.project
    options = @task_result.options

    # if project was deleted, raise an exception
    raise MissingProjectError, "Missing πroject, possibly deleted?" unless @project
    raise InvalidEntityError, "Missing Entity" unless @entity

    ###
    ### Handle cancellation
    ###
    if @task_result.cancelled
      _log "Cancelled, returning without running!"
      return
    end

    ###
    ### Handle already finished or already started results with the
    ### same name in the same scan. Check for existing "same" task results
    ### that havec already started or completed, and bail early
    ### if that's the case
    ###
    return_early = false
    if @task_result.scan_result
      our_task_result_name = "#{@task_result.name}"

      # query existing results, limit to those that have been started
      existing_task_results = Intrigue::Core::Model::TaskResult.scope_by_project(@project.name).where(
        name: our_task_result_name).exclude(timestamp_start: nil).exclude(id: @task_result.id)

      # if we've already completed another one, return eearly
      if existing_task_results.first
        _log "This task is in progress, or has already been completed in this project"

        # we want to be able to intelligently re-run flows we havent seen before... this is a way to do that
        if @task_result.autoscheduled == false || (@entity.enrichment_tasks.include?(@task_result.name) && @project.allow_reenrich)
          _log_good "Allowing re-run, this is a user-scheduled task and re-enrich is enabled"
          return_early = false

        # but default to failing on running stuff we havent yet seen. ...
        # there is probably a better way to do this by caching results and snagging them... TODO
        else
          _log_error "Returning, this task was already scheduled or run!"
          return_early = true
        end
      end
    end

    if return_early
      @task_result.complete = true
      @task_result.timestamp_end = Time.now.getutc.iso8601
      @task_result.logger.save_changes
      @task_result.save_changes
      _log "Returning early, we already have this result."
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
            begin

              run # Run the task, which will update @task_result

            ###
            ## Robust error handling is a must
            ###
            rescue MissingTaskConfigurationError => e

              _log_error "Missing task configuration, please check configuration for this task: #{e}"
              Intrigue::NotifierFactory.default.each { |x|  # if configured, notify!
                x.notify("Missing Task Configuration: #{@entity.type} #{@entity.name} #{e}" , @task_result) }

            rescue  InvalidTaskConfigurationError => e

              _log_error "Invalid task configuration, please check configuration for this task: #{e}"
              Intrigue::NotifierFactory.default.each { |x| # if configured, notify!
                x.notify("Invalid Task Configuration: #{@entity.type} #{@entity.name} #{e}" , @task_result) }

            rescue InvalidEntityError => e

              _log_error "Invalid entity attempted #{e}"
              _log_error "Probably a bug, report at: https://github.com/intrigueio/intrigue-core/issues"

              Intrigue::NotifierFactory.default.each { |x| # if configured, notify!
                x.notify("Invalid entity attempted: #{@entity.type} #{@entity.name} #{e}" , @task_result) }

            rescue SystemResourceMissing => e

              _log_error "Missing system resource (external program?): #{e}"
              Intrigue::NotifierFactory.default.each { |x| # if configured, notify!
                x.notify("Missing system resource (external program?): #{@entity.type} #{@entity.name} #{e}" , @task_result) }

            rescue TimeoutError => e

              _log_error "System timed out running a task: #{e}"
              Intrigue::NotifierFactory.default.each { |x| # if configured, notify!
                x.notify("System timed out running a task: #{@entity.type} #{@entity.name} #{e}" , @task_result) }

            end

            end_time = Time.now.getutc.iso8601
            _log "Task run finished at #{end_time}!"
        else
          _log_error "Task setup failed, bailing out w/o running!"
        end
      end

      ##########################################
      # Finalize Enrichment and Start Workflow #
      ##########################################

      # grab metadata to check if this is enrichment tasks
      is_enrichment_task = @entity.enrichment_tasks.include? "#{@task_result.task_name}"
      # first update enriched count (do it in a transaction so the read/write happens together)

      is_fully_enriched = false #default
      if is_enrichment_task

        # do this in a transaction so we don't accidentally miss one completing in another thread
        $db.transaction do
          # get it
          @entity = Intrigue::Core::Model::Entity.find(:id => @entity.id)
          etc = @entity.enrichment_tasks_completed
          etc << @task_result.task_name
          # set it
          @entity.enrichment_tasks_completed = etc.uniq
          @entity.save
        end
        # now check it
        is_fully_enriched = @entity.enrichment_tasks_completed.count == @entity.enrichment_tasks.uniq.count
        puts "DEBUG: Checking if fully enriched: #{@task_result.task_name} (#{is_enrichment_task})"
        puts "DEBUG: #{@entity.name}, Completed: #{@entity.enrichment_tasks_completed} (#{@entity.enrichment_tasks_completed.count}), #{@entity.enrichment_tasks.count}"
      end

      # Now, if this is an enrichment type task, we want to mark our enrichemnt complete
      # if it's true, we can set it and launch our workflow!
      #
      # ... if we have multiple, we need to compare counts
      #
      # ... but only if we're fully enriched will we need to go through this flow.
      #
      # note that we dont want to kick off enrichment multiple times, so let's just check
      # for equivalence here vs >=
      #
      if is_enrichment_task && is_fully_enriched

        # Now, set enriched since this is our final enrichment task!
        puts "DEBUG: Setting enriched!"
        @entity.enriched = true
        @entity.save

        ### AND we can decide scope based on complete information now,
        # note that does take into account the previously-set status
        # ... for more info, (see the entity's scoped? method )
        @entity.set_scoped!(@entity.scoped?, 'entity_scoping_rules')

        # In order to ensure all linked issues take our entity's scoped status, we
        # iterate through them, setting the entity's scoped status on them
        @entity.issues.each do |i|
          i.scoped = @entity.scoped
          i.save_changes
        end

        ###
        ## NOW, KICK OFF WORKFLOWS for SCOPED ENTITIES ONLY
        ###
        if @entity.scoped

          # WORKFLOW LAUNCH (ONLY IF WE ARE ATTACHED TO A WORKFLOW)
          # if this is part of a scan and we're in depth
          if @task_result.scan_result && @task_result.depth > 0

            workflow_name = @task_result.scan_result.workflow
            @task_result.log "Launching workflow #{workflow_name} on #{@entity.name}"
            workflow = Intrigue::WorkflowFactory.create_workflow_by_name(workflow_name)

            unless workflow
              raise InvalidWorkflowError, "Unable to continue, missing workflow: #{workflow_name}!!!"
            end

            ##
            ## Start the workflow!
            ##
            @task_result.log "Launching workflow on #{@entity.name} after #{@task_result.name}"
            workflow.start(@entity, @task_result)

          else
            @task_result.log "No workflow configured for #{@entity.name}!"
          end


          #####################
          #   Call Handlers   #
          #####################

          scan_result = @task_result.scan_result
          if scan_result
            scan_result.decrement_task_count

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
          _log "Entity not scoped, no workflow will be run."
        end

      else
        _log "Not an enrichment task, skipping workflow generation"
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
    if user_options && user_options.kind_of?(Array) && !user_options.empty?
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
          #else
          #  _log_error "Unused option provided: #{user_option}"
          end

        end

      end
      _log "User options accepted: #{@user_options}"
    else
      _log "No user options set"
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
