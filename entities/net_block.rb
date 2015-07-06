module Intrigue
module Entity
class NetBlock < Base

  def metadata
    {
      :type => "NetBlock",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/
  end

end
end
end
