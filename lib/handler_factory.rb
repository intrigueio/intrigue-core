module Intrigue
class HandlerFactory

  #
  # Register a new handler
  #
  def self.register(klass)
    @handlers = [] unless @handlers
    @handlers << klass if klass
  end

  #
  # Similar interface to task factory
  #
  def self.list
    handlers
  end

  
  #
  # Provide the full list of handlers
  #
  def self.handlers
    @handlers
  end

  #
  # Check to see if this handler exists (check by type)
  #
  def self.include?(type)
    @handlers.each { |h| return true if "#{h.metadata[:name]}" == "#{type}" }
  false
  end

  #
  # create_by_type(type)
  #
  # Takes:
  #  type - String
  #
  # Returns:
  #   - A handler, which you can call generate on
  #
  def self.create_by_type(type)
    @handlers.each { |h| return h.new if "#{h.metadata[:name]}" == "#{type}" }
  false
  end

end
end
