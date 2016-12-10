module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhoneNumber",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
