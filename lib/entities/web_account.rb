module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def metadata
    {
      :type => "WebAccount",
      :required_attributes => ["name","domain","uri"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/ &&
    attributes["domain"] =~ /^.*$/ &&
    attributes["uri"] =~ /^http.*$/
  end

end
end
end
