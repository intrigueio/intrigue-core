module Intrigue
module Entity
class EmailAddress < Base

  def metadata
    {
      :type => "EmailAddress",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^[a-zA-Z0-9\.].*@[a-zA-Z0-9\.].*/
  end

end
end
end
