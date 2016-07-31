module Intrigue
module Task
module Generic

  private
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
    string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
  end

  def _encode_hash(hash)
    hash.each {|k,v| hash[k] = _encode_string(v) if v.kind_of? String }
  hash
  end

  #
  # This is a helper method, use this to create entities from within tasks
  #
  def _create_entity(type, hash)

    # Clean up in case there are encoding issues
    hash = _encode_hash(hash)

    # Now check fo r santity
    raise "INVALID ENTITY, no name!" unless hash["name"]

    short_name = _encode_string(hash["name"][0,199])
    entity = Intrigue::Model::Entity.scope_by_project(@project_name).first(:name => short_name)

    # Merge the details if it exists
    if entity
      entity.details = entity.details.merge(hash)
      entity.save
    else
      # Create the entity, validating the attributes
      entity = Intrigue::Model::Entity.create({
                 :type => eval("Intrigue::Entity::#{type}"),
                 :name => short_name,
                 :details => hash,
                 :project => Intrigue::Model::Project.get(@project_id)
               })
    end

    # If we don't have an entity now, fail.
    unless entity
      _log_error "Unable to verify & save entity: #{type} #{hash.inspect}"
      return false
    end

    # Make sure we link the parent task & save
    entity.task_results << @task_result
    entity.save

    # Add to our result set for this task
    @task_result.add_entity entity

  # return the entity
  entity
  end

  def _canonical_name
    "#{self.metadata[:name]}: #{self.metadata[:version]}"
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
        _log "Using key ending in #{value[-3..-1]}"
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
    method = metadata[:allowed_options].each do |allowed_option|
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
