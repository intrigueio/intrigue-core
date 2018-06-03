module Intrigue
module Entity
class TrelloOrganization < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Trello Organization",
      :description => "An organization configured in Trello.com",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
