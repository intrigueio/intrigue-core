module Intrigue
module Entity
class PhysicalLocation < Intrigue::Model::Entity

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


end
end
end
