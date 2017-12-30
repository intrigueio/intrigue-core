module Intrigue
module Entity
class AsNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AsNumber",
      :description => "An Autonomous System Number",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
