module Intrigue
module Entity
class TrelloAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Trello Account",
      :description => "An account configured in Trello.com",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
