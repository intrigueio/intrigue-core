module Intrigue
module Entity
class UriHeader < Base

  def metadata
    {
      :type => "UriHeader",
      :required_attributes => ["name","content"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/ &&
    attributes[:content] =~ /^.*$/
  end

end
end
end
