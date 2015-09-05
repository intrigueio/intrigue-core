module Intrigue
module Entity
class Uri < Base

  def metadata
    {
      :type => "Uri",
      :required_attributes => ["name","uri"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
