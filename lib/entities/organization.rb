module Intrigue
module Entity
class Organization < Intrigue::Model::Entity

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
