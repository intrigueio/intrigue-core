module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhoneNumber",
      :description => "A Phone Number",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    "#{details["extracted_from"]}"
  end

end
end
end
