module Intrigue
module Entity
class Info < Base

  def metadata
    {
      :type => "Info",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*$/
  end

end
end
end
