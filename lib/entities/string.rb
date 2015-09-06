module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def metadata
    {
      :type => "String",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
