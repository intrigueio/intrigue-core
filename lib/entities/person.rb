module Intrigue
module Entity
class Person < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Person",
      :description => "TODO"
    }
  end


  def validate_content
    @name =~ /^.*$/
  end

end
end
end
