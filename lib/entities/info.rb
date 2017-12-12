module Intrigue
module Entity
class Info < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Info",
      :description => "Generic Information",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
