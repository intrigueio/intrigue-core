module Intrigue
module Entity
class WebAccount < Base

  def metadata
    {
      :type => "WebAccount",
      :required_attributes => ["name","domain","uri"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/ &&
    attributes["domain"] =~ /^.*$/ &&
    attributes["name"] =~ /^http.*$/
  end

end
end
end
