module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

  def metadata
    {
      :type => "EmailAddress",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/
  end

end
end
end
