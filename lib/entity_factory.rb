###
### Entity factory: Standardize the creation and valiadation of entities
###
module Intrigue
class EntityFactory

  #
  # Register a new entity
  #
  def self.register(klass)
    @entities = [] unless @entities
    @entities << klass if klass
  end

  #
  # Provide the full list of entities
  #
  def self.list
    @entities
  end

  #
  # Check to see if this entity exists (check by type)
  #
  def self.include?(type)
    @entities.each do |t|
      entity_object = t.new
      if (entity_object.metadata[:type] == type)
        return true # Create a new object and send it back
      end
    end
  false
  end

end
end
