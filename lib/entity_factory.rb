module Intrigue
class EntityFactory
  #
  # Register a new entity
  #
  def self.register(klass)
    @entity_types = [] unless @entity_types
    @entity_types << klass if klass
  end

  # NOTE: We don't auto-register entities like the other factories (handled by
  # single table inheritance)
  def self.entity_types
    @entity_types
  end

end
end
