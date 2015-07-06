module Intrigue
module Entity
class String < Base

  def metadata
    {
      :type => "String",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^[\d].*$/
  end

end
end
end
