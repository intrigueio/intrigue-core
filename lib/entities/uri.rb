module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Uri",
      :description => "A Uniform Resource Identifier (URI) is a string of characters used to identify a resource."
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
