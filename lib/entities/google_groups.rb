module Intrigue
module Entity
class GoogleGroups < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GoogleGroups",
      :description => "Google Groups",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    "#{details["uri"]}"
  end

end
end
end
