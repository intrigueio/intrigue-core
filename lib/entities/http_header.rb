module Intrigue
module Entity
class HttpHeader < Intrigue::Model::Entity

  def metadata
    {
      :type => "HttpHeader",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*$/
  end

end
end
end
