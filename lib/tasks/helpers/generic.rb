module Intrigue
module Task
module Generic

   def self.included(base)
     include Intrigue::Task::Web
   end

   def require_enrichment
    
    entity_enriched = @entity.enriched?
    cycles = 200 
    max_cycles = cycles

    until entity_enriched || cycles == 0
      _log "Waiting up to 10m for entity to be enriched... (#{cycles-=1} / #{max_cycles})"
      sleep 3
      entity_enriched = Intrigue::Core::Model::Entity.first(:id => @entity.id).enriched?
    end

    # re-pull
    @entity = Intrigue::Core::Model::Entity.first(:id => @entity.id)
    
  end

  private

  def _threaded_iteration(thread_count, input_queue, funct)

    # Create our queue of work from the checks in brute_list
    #output_queue = Queue.new

    # Create a pool of worker threads to work on the queue
    workers = (0...thread_count).map do
      Thread.new do
        begin
          while item = input_queue.pop(true)
            # kick it off an save our ouput to the out queue
            funct.call(item)
          end # end while
        rescue ThreadError
        end
      end
    end; "ok"
    workers.map(&:join); "ok"

  #output_queue
  end # end run method

  ###
  ### Helper method to reach out to the entity manager
  ###
  def _create_entity(type, hash, primary_entity=nil)

    # just in case we were given a hash with symbolized keys, convert to strings for
    # our purposes... bitten by the bug a bunch lately
    hash = hash.collect{|k,v| [k.to_s, v] }.to_h

    # No need for a name in the hash now, remove it & pull out the name from the hash
    name = hash.delete("name")

    # Create or merge the entity
    EntityManager.create_or_merge_entity(@task_result.id, type, name, hash, primary_entity)
  end

  ###
  ### Helper method .. should this check with the entity manager?
  ###
  def _entity_exists?(type,name)
    entity_exists?(@entity.project, type, name)
  end

  ###
  ### Logging helpers
  ###
  def _log(message)
    @task_result.logger.log message
  end

  def _log_debug(message)
    @task_result.logger.log_debug message
  end

  def _log_error(message)
    @task_result.logger.log_error message
  end

  def _log_fatal(message)
    @task_result.logger.log_fatal message
  end

  def _log_good(message)
    @task_result.logger.log_good message
  end

  # Convenience Method to execute a system command semi-safely
  # by default, timesout after 5 minutes (300 seconds)
  # default working directory is /tmp
  #  !!!! Don't send anything to this without first whitelisting user input!!!
  def _unsafe_system(command, timeout = 300, workingdir = "/tmp", tick=1)
    
    command_stdout = nil
    command_stderr = nil

    Dir.chdir workingdir do
      begin

        # Start task in another thread, which spawns a process
        process = ::Open3.popen3(ENV, command + ';') do |stdin, stdout, stderr, thread|
          stdin.close
          stdout_buffer   = stdout.read
          stderr_buffer   = stderr.read
          command_stdout  = stdout_buffer if stdout_buffer.length > 0
          command_stderr  = stderr_buffer if stderr_buffer.length > 0
          stdout.close
          stderr.close
          thread.value # Wait for Process::Status object to be returned
        end

        # Get the pid of the spawned process
        pid = process.pid
        start = Time.now

        while (Time.now - start) < timeout and !process.exited?
          # Wait up to `tick` seconds for output/error data
          Kernel.select([stderrout], nil, nil, tick)
          # Try to read the data
          begin
            sleep 1
          rescue IO::WaitReadable
            # A read would block, so loop around for another select
          rescue EOFError
            # Command has completed, not really an error...
            break
          end
        end

        # Give Ruby time to clean up the other thread
        sleep 1

        unless process.exited?
          # We need to kill the process, because killing the thread leaves
          # the process alive but detached, annoyingly enough.
          puts "Timeout exceeded! Killing thread..."
          Process.kill("TERM", pid)
        end

      end
      
    end

  command_stdout
  end
  ###
  ### Helpers for handling encoding
  ###

  def _encode_string(string)
    return string unless string.kind_of? String
    string.scrub("?") #.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
  end

  def _encode_hash(hash)
    return hash unless hash.kind_of? Hash
    hash.each {|k,v| hash[k] = _encode_string(v) if v.kind_of? String }
  hash
  end

  def _call_handler(handler_name)
    @task_result.handle(handler_name)
  end

  def _notify(message)
    if Intrigue::NotifierFactory.default
      _log "Notifying via default channels"
      Intrigue::NotifierFactory.default.each { |x| x.notify(message, @task_result) }
    else 
      _log "Unable to notify on default channels!"
    end
  end

  def _notify_type(notifier_type, message)
    _log "Notifying via all #{notifier_type} channels"
    Intrigue::NotifierFactory.create_all_by_type(notifier_type).each do |n|
      n.notify(message, @task_result)
    end
  end

  def _notify_specific(notifier_name, message)
    _log "Notifying via #{notifier_name} channel"
    x = Intrigue::NotifierFactory.create_by_name(notifier_name)
    x.notify(message, @task_result)
  end

  ## Helper methods for getting common entity data
  def _get_entity_detail(detail_name)
    @entity.get_detail(detail_name)
  end

  def _set_entity_detail(detail_name, detail_value)
    @entity.set_detail(detail_name, detail_value)
  end

  def _get_entity_details
    @entity.get_details
  end

  # Deprecated, use... 
  def _get_and_set_entity_details(hash)
    @entity.get_and_set_details hash
  end

  def _get_entity_name
    "#{@entity.name}"
  end

  def _get_entity_type_string
    "#{@entity.type_string}"
  end

  ### GLOBAL CONFIG INTERFACE
  def _get_system_config(key)
    Intrigue::Core::System::Config.load_config
    value = Intrigue::Core::System::Config.config[key]
  end

  def _get_task_config(key)
    begin
      
      #Intrigue::Core::System::Config.load_config
      error_message = "Please enter your #{key} setting in 'Configure -> Task Configuration'"
      config = Intrigue::Core::System::Config.config["intrigue_global_module_config"]
      value = config[key]["value"]
    
      unless value && value != ""
        raise MissingTaskConfigurationError.new error_message
      end

    end

  value
  end

  ###
  ### XXX TODO - move this up into the setup method and make it happen automatically
  ###
  def _get_option(name)

    # Start with nothing
    value = nil

    # First, get the default value by cycling through the allowed options
    method = self.class.metadata[:allowed_options].each do |allowed_option|
      value = allowed_option[:default] if allowed_option[:name] == name
    end

    # Then, cycle through the user-provided options
    @user_options.each do |user_option|
      value = user_option[name] if user_option.key?(name)
    end

  value
  end


end
end
end
