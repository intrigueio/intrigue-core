module Intrigue
module Entity
class Username < Base

  def metadata
    {
      :type => "Username",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
