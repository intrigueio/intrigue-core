module Intrigue
module Task
module Generic

  private

  ###
  ### Helper method to reach out to the entity manager
  ###
  def _create_entity(type, hash, primary_entity=nil)

    # No need for a name in the hash now, remove it & pull out the name from the hash
    name = hash.delete("name")

    # Create or merge the entity
    EntityManager.create_or_merge_entity(@task_result, type, name, hash, primary_entity)
  end

  ###
  ### Logging helpers
  ###
  def _log(message)
    @task_result.logger.log message
    #@task_result.logger.save
  end

  def _log_good(message)
    @task_result.logger.log_good message
    #@task_result.logger.save
  end

  def _log_error(message)
    @task_result.logger.log_error message
    #@task_result.logger.save
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

  ## Helper methods for getting common entity data
  def _get_entity_attribute(attrib_name)
    if attrib_name == "name"
      "#{@task_result.base_entity.name}"
    else
      "#{@task_result.base_entity.get_detail[attrib_name]}"
    end
  end

  def _get_entity_name
    "#{@task_result.base_entity.name}"
  end

  def _get_entity_type_string
    "#{@task_result.base_entity.type}".split(":").last
  end

  ### GLOBAL CONFIG INTERFACE

  def _get_global_config(key)
    begin
      value = Intrigue::Config::GlobalConfig.new.config["intrigue_global_module_config"][key]["value"]
      if value && value != ""
        _log "Using config #{key} ending in #{value[-3..-1]}"
      else
        _log "API Key (#{key}) is blank or missing. Check the admin tab!"
      end
    rescue NoMethodError => e
      _log "Error, invalid config key requested (#{key}) #{e}"
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

    puts "Returning value #{value} for option #{name}"

  value
  end


end
end
end
