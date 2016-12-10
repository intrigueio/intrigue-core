module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "String",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
