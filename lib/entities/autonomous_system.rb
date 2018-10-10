module Intrigue
module Entity
class AutonomousSystem < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AutonomousSystem",
      :description => "Network Routes",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^(as|AS).?[0-9].*$/
  end

end
end
end
