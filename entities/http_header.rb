module Intrigue
module Entity
class HttpHeader < Base

  def metadata
    {
      :type => "HttpHeader",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/
  end

end
end
end
