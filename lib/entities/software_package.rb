module Intrigue
module Entity
class SoftwarePackage < Intrigue::Model::Entity

  def metadata
    {
      :type => "SoftwarePackage",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
