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
  # Grab all notifiers with a "default" attribute
  #
  def self.default
    # select all with the default attribute
    enabled_configs = $global_config.config["intrigue_notifiers"].select{|k,v| v["enabled"] && v["default"] }
    # create notifiers for them
    enabled_configs.map{|k,v| self.create_by_type_and_config(v["type"],v)}
  end

  # create_by_name(name)
  #
  # Takes:
  #  name - String
  #
  # Returns:
  #   - A notifier, which you can call notify on
  #
  def self.create_by_name(name)
    notifiers = []
    $global_config.config["intrigue_notifiers"].each do |k,v|
      next unless v["enabled"]
      if k == name
        config = v
        return @notifiers.select{ |n| n.metadata[:type] == config["type"] }.first.new(config)
      end
    end
  end

  # create_all_by_type(type,config)
  #
  # Takes:
  #  type - String
  #  config - Hash
  #
  # Returns:
  #   - A notifier, which you can call notify on
  #
  def self.create_all_by_type(type)
    notifiers = []
    $global_config.config["intrigue_notifiers"].each do |k,v|
      next unless v["enabled"]
      if v["type"] == type
        config = v
        notifiers << self.create_by_type_and_config(config["type"],config)
      end
    end
  notifiers
  end

  #
  # create_by_type_and_config(type,config)
  #
  # Takes:
  #  type - String
  #  config - Hash
  #
  # Returns:
  #   - A notifier, which you can call notify on
  #
  def self.create_by_type_and_config(type,config)
    @notifiers.select{|n| n.metadata[:type] == "#{type}" }.first.new(config)
  end

end
end
