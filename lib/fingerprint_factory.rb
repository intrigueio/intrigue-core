module Intrigue
class FingerprintFactory

  #
  # Register a new handler
  #
  def self.register(klass)
    @fingerprints = [] unless @fingerprints
    @fingerprints << klass if klass
  end

  #
  # Provide the full list of handlers
  #
  def self.fingerprints
    @fingerprints
  end

end
end
