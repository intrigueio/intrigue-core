module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhoneNumber",
      :description => "TODO"
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
