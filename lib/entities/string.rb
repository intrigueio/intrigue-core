module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "String",
      :description => "TODO"
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
