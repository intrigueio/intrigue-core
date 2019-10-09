module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhoneNumber",
      :description => "A Phone Number",
      :user_creatable => true,
      :example => "555-555-5555"
    }
  end

  def validate_entity
    name =~ /^\D*([2-9]\d{2})(\D*)([2-9]\d{2})(\D*)(\d{4})\D*$/
  end

  def detail_string
    "#{details["origin"]}"
  end
  
end
end
end
