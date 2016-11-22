module Intrigue
module Task
module Generic

  private

  def _create_entity(type,hash)
    EntityFactory.create_entity(@project,@task_result,type,hash)
  end

  ###
  ### Logging helpers
  ###

  def _log(message)
    @task_result.logger.log message
  end

  def _log_good(message)
    @task_result.logger.log_good message
  end

  def _log_error(message)
    @task_result.logger.log_error message
  end

  # Convenience Method to execute a system command semi-safely
  #  !!!! Don't send anything to this without first whitelisting user input!!!
  def _unsafe_system(command)

    ###                  ###
    ###  XXX - SECURITY  ###
    ###                  ###

    if command =~ /(\||\;|\`)/
      #raise "Illegal character"
      _log_error "FATAL Illegal character in #{command}"
      return
    end

    `#{command}`
  end

  ###
  ### Helpers for handling encoding
  ###

  def _encode_string(string)
    return string unless string.kind_of? String
    string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
  end

  def _encode_hash(hash)
    return hash unless hash.kind_of? Hash
    hash.each {|k,v| hash[k] = _encode_string(v) if v.kind_of? String }
  hash
  end

  def _canonical_name
    "#{self.class.metadata[:name]}: #{self.class.metadata[:version]}"
  end

  # helper method, gets an attribute on the base entity
  def _get_entity_attribute(attrib_name)
    "#{@task_result.base_entity.details[attrib_name]}"
  end

  def _get_entity_type
    "#{@task_result.base_entity.type}".split(":").last
  end

  def _get_global_config(key)
    begin
      value = Intrigue::Config::GlobalConfig.new.config["intrigue_global_module_config"][key]["value"]
      if value && value != ""
        _log "Using config #{key} ending in #{value[-3..-1]}"
      else
        _log "API Key (#{key}) is blank or missing. Check the admin tab!"
      end
    rescue NoMethodError => e
      puts "Error, invalid config key requested (#{key}) #{e}"
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
      value = user_option[name] if user_option[name]
    end

  value
  end


end
end
end
