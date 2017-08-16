module Intrigue
module Entity
class File < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "File",
      :description => "A File"
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

end
end
end
