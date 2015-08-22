module Intrigue
module Entity
class Organization < Base

  def metadata
    {
      :type => "Organization",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
