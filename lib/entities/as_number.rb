module Intrigue
module Entity
class AsNumber < Intrigue::Model::Entity

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
