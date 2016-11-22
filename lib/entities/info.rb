module Intrigue
module Entity
class Info < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Info",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/
  end

end
end
end
