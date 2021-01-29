module Intrigue
module Entity
class AutonomousSystem < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AutonomousSystem",
      description: "Unique number that's available globally to exchange network routes",
      user_creatable: true,
      example: "AS1234"
    }
  end

  def validate_entity
    name.match asn_regex
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  false # otherwise false
  end
  
end
end
end
