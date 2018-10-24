module Intrigue
module Ident
class CheckFactory

  #
  # Register a new handler
  #
  def self.register(klass)
    @checks = [] unless @checks
    @checks << klass if klass
  end

  #
  # Provide the full list of checks
  #
  def self.all
    @checks
  end

end
end
end
