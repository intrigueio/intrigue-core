module Intrigue
module Entity
class Analytics < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Analytics",
      :description => "Google Analytics ID",
      :user_creatable => true,
      :example => "Literally any string in this format UA-{numbers}"
    }
  end

  def validate_entity
    name =~ /^UA-.\d.*.\d/i
  end



end
end
end
