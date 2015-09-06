module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def metadata
    {
      :type => "PhoneNumber",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
