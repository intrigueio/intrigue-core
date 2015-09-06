module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def metadata
    {
      :type => "NetBlock",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
