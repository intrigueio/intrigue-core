module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Uri",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
