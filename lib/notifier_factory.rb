module Intrigue
class NotifierFactory

  #
  # Register a new notifier
  #
  def self.register(klass)
    @notifiers = [] unless @notifiers
    @notifiers << klass if klass
  end

  #
  # Provide the full list of notifier
  #
  def self.notifiers
    @notifiers
  end

  #
  # Check to see if this notifier exists (check by type)
  #
  def self.include?(type)
    @notifiers.select { |n| "#{n.metadata[:name]}" == "#{type}" }
  false
  end


  #
  # Provide the full list of notifier
  #
  def self.enabled
    global_config = $global_config
    enabled_configs = global_config.config["intrigue_notifiers"].select{|k,v| v["enabled"] }
    enabled_configs.map {|k,v| self.create_by_type k,v }
  end

  #
  # create_by_type(type,config)
  #
  # Takes:
  #  type - String
  #
  # Returns:
  #   - A notifier, which you can call notify on
  #
  def self.create_by_type(type,config)
    puts "creating new notifier of type #{type}"
    @notifiers.select{ |n| "#{n.metadata[:name]}" == "#{type}" }.first.new(config)
  end

end
end
