module Intrigue
module Entity
class File < Base

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
