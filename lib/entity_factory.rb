###
### Entity factory: Standardize the creation and valiadation of entities
###
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
  def self.include?(name)
    @entities.each do |t|
      entity_object = t.new
      if (entity_object.metadata[:type] == type)
        return true # Create a new object and send it back
      end
    end
  false
  end


  #
  # create_by_type(type, attributes)
  #
  # Creates a new entity, providing the entity type, and the
  # attributes for this particular entity. If unable to create
  # raise an error
  #
  # Takes:
  #  type - String
  #  attributes - Hash
  #
  # Returns:
  #  An entity (subclass of type Intrigue::Entity::Base) if successful or nil (fail)
  #
  def self.create_by_type(type,attributes)

    @entities.each do |e|
      # Create a new entity object
      entity_object = e.new

      # Check to see if this is the matching type
      if (entity_object.metadata[:type] == type)

        # If so, validate the attributes to make sure we can
        # create this entity with these attributes (and set them if it validates)
        if entity_object.set_attributes(attributes)

          # Success!
          return entity_object

        else

          # Fail!
          ### XXX - we'll need to deal with this
          raise "Unable to validate entity"

        end
      end
    end

    ### XXX - exception handling? Should this return nil?
    raise "No entity with type: #{type} (#{attributes})"
  end

end
