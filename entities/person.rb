module Intrigue
module Entity
class Person < Base

  def metadata
    {
      :type => "Person",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/
  end

end
end
end
