module Intrigue
module Entity
class Person < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Person",
      :description => "A Person"
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
