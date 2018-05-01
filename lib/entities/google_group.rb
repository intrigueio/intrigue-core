module Intrigue
module Entity
class GoogleGroup < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GoogleGroup",
      :description => "A Google Group",
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
