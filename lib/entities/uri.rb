module Intrigue
module Entity
class Uri < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Uri",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/
  end

end
end
end
