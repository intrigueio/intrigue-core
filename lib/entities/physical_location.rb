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
    name =~ /^[\w\s\d\.\-\_\&\;\:\,\@]*$/
    #details["latitude"] =~ /^([-+]?\d{1,2}[.]\d+)$/ &&
    #details["longitude"] =~ /^([-+]?\d{1,3}[.]\d+)$/
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end


end
end
end
