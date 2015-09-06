module Intrigue
module Entity
class File < Intrigue::Model::Entity

  def metadata
    {
      :type => "File",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
