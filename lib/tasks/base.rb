require 'timeout'

module Intrigue
class BaseTask
  include Intrigue::Task::Generic
  include Intrigue::Task::Helper

  include Sidekiq::Worker
  sidekiq_options :queue => "task", :backtrace => true

  def self.inherited(base)
    TaskFactory.register(base)
  end

  def perform(task_result_id)

    #######################
    # Get the Task Result #
    #######################
    @task_result = Intrigue::Model::TaskResult.first(:id => task_result_id)

    raise "Unable to find task result by id #{task_result_id}. Bailing." unless @task_result

    @entity = @task_result.base_entity
    @project = @task_result.project

    options = @task_result.options

    # we must have these things to continue
    raise "Unable to find task_result. Bailing." unless @task_result
    raise "Unable to find project. Bailing." unless @project
    raise "Unable to find entity. Bailing." unless @entity

    # We need a flag to skip the actual setup, run, cleanup of the task if
    # the caller gave us something broken. We still want to get the final
    #  task result back to the caller though (so no raise). Assume it's good,
    # and check input along the way.
    broken_input_flag = false

    # Do a little logging. Do it for the kids!
    _log "Id: #{task_result_id}"
    _log "Entity: #{@entity.type_string}##{@entity.name}"
    #_log "Options: #{options}"

    ###################
    # Sanity Checking #
    ###################
    allowed_types = self.class.metadata[:allowed_types]

    # Check to make sure this task can receive an entity of this type
    unless allowed_types.include?(@entity.type_string) || allowed_types.include?("*")
      _log_error "Unable to call #{self.class.metadata[:name]} on entity: #{@entity}"
      broken_input_flag = true
    end

    ###########################
    #  Setup the task result  #
    ###########################
    @task_result.task_name = self.class.metadata[:name]
    @task_result.timestamp_start = Time.now.getutc
    #@task_result.id = task_result_id

    ###################################
    # Perform the setup->run workflow #
    ###################################
    unless broken_input_flag
      # Setup creates the following objects:
      # @user_options - a hash of task options
      # @task_result - the final result to be passed back to the caller
      _log "Calling setup()"
      if setup(task_result_id, @entity, options)
        #begin
          #Timeout.timeout($intrigue_global_timeout) do # 15 minutes should be enough time to hit a class b for a single port w/ masscan
            _log "Calling run()"
            # Save the task locally
            @task_result.save
            # Run the task, which will update @task_result and @task_result
            run()
            _log_good "Run complete. Ship it!"
          #end
        #rescue Timeout::Error
        #  _log_error "Timed out"
        #end
      else
        _log_error "Setup failed, bailing out!"
      end
    end

    #
    # Mark it complete and save it
    #
    # http://stackoverflow.com/questions/178704/are-unix-timestamps-the-best-way-to-store-timestamps
    @task_result.timestamp_end = Time.now.getutc
    @task_result.complete = true
    _log "Calling cleanup!"

    #
    # Handlers!
    #
    # (see lib/report/handlers)
    @task_result.handlers.each do |handler_type|
      _log "Processing #{handler_type} handler."
      begin
        handler = HandlerFactory.create_by_type(handler_type)
        response = handler.process(@task_result)
      rescue Exception => e
        _log_error "Unable to process handler #{handler_type}: #{e}"
        _log_error "Got response: #{response}"
      end
    end

    cleanup
    @task_result.save
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
              regex = /^-?\d+$/
            elsif allowed_option[:regex] == "boolean"
              #_log "Regex should match a boolean"
              regex = /(true|false)/
            elsif allowed_option[:regex] == "alpha_numeric"
              #_log "Regex should match an alpha-numeric string"
              regex = /^[a-zA-Z0-9\_\;\(\)\,\?\.\-\_\/\~\=\ \,\?\*]*$/
            elsif allowed_option[:regex] == "alpha_numeric_list"
              #_log "Regex should match an alpha-numeric list"
              regex = /^[a-zA-Z0-9\_\;\(\)\,\?\.\-\_\/\~\=\ \,\?\*]*$/
            elsif allowed_option[:regex] == "filename"
              #_log "Regex should match a filename"
              regex = /(?:\..*(?!\/))+/
            elsif allowed_option[:regex] == "ip_address"
              #_log "Regex should match an IP Address"
              regex = /^(\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*)|((\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}))$/
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

            if allowed_option[:type] == "Integer"
              # convert to integer
              #_log "Converting #{user_option["name"]} to an integer"
              user_option["value"] = user_option["value"].to_i
            elsif allowed_option[:type] == "String"
              # do nothing, we can just pass strings through
              #_log "No need to convert #{user_option["name"]} to a string"
              user_option["value"] = user_option["value"]
            elsif allowed_option[:type] == "Boolean"
              # use our monkeypatched .to_bool method (see initializers)
              #_log "Converting #{user_option["name"]} to a bool"
              user_option["value"] = user_option["value"].to_bool if user_option["value"].kind_of? String
            else
              # throw an error, we likely have a string we don't know how to cast
              _log_error "Don't know how to handle this option when it's given to us as a string, failing!"
              return nil
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

  def cleanup
    @task_result.logger.save
  end
  #
  #########################################################

  # Override this method if the task has external dependencies
  def check_external_dependencies
    true
  end

end
end
