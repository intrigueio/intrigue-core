module Intrigue
module Entity
class Person < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "Person",
      :description => "A Person",
      :user_creatable => true,
      :example => "Bazooka Joe"
    }
  end

  def validate_entity
    name.match /^[[[:word:]]\,\s]+$/
  end

  def detail_string
    "#{details["origin"]}"
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

end
end
end
