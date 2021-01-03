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
    return true if self.allow_list
    return false if self.deny_list
  
  false
  end

end
end
end
