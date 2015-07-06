module Intrigue
module Entity
class PhysicalLocation < Base

  def metadata
    {
      :type => "PhysicalLocation",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/ #&&
    #attributes[:latitude] =~ /^([-+]?\d{1,2}[.]\d+)$/ &&
    #attributes[:longitude] =~ /^([-+]?\d{1,3}[.]\d+)$/
  end

end
end
end
