module Intrigue
module Entity
class PhysicalLocation < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "PhysicalLocation",
      :description => "A Physical Location",
      :user_creatable => false
    }
  end

  def validate_entity
    name.match /^[\w\s\d\.\-\_\&\;\:\,\@]*$/
    #details["latitude"].match /^([-+]?\d{1,2}[.]\d+)$/ &&
    #details["longitude"].match /^([-+]?\d{1,3}[.]\d+)$/
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  false
  end

end
end
end
