module Intrigue
module Entity
class Screenshot < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Screenshot",
      :description => "A Screenshot of a Webpage",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/ # TODO - tighten this up
  end


end
end
end
