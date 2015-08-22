module Intrigue
module Entity
class Screenshot < Base

  def metadata
    {
      :type => "Screenshot",
      :required_attributes => ["name", "uri"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/ # XXX - too loose
    #attributes[:file] =~ /^.*$/ # XXX - too loose
  end

end
end
end
