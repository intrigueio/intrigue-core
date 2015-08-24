module Intrigue
class ReportFactory

  #
  # Register a new handler
  #
  def self.register(klass)
    @handlers = [] unless @handlers
    @handlers << klass if klass
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
    @handlers.each { |h| return true if "#{h.type}" == "#{type}" }
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

    # If we don't know it, fail
    raise "Unknown handler type: #{type}" unless include? type

    return_handler = nil
    @handlers.each do |h|
      return_handler = h.new if "#{type}" == "#{h.type}"
    end

  return_handler
  end

end
end
