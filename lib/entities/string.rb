module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "String",
      :description => "A Generic Search String",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
