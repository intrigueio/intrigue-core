module Intrigue
module Entity
class Person < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Person",
      :description => "TODO"
    }
  end


  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
