module Intrigue
module Entity
class PhoneNumber < Base

  def metadata
    {
      :type => "PhoneNumber",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/
  end

end
end
end
