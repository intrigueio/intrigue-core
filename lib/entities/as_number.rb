module Intrigue
module Entity
class AsNumber < Base

  def metadata
    {
      :type => "AsNumber",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
