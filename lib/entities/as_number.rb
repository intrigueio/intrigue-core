module Intrigue
module Entity
class AsNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AsNumber",
      :description => "TODO"
    }
  end

  def validate
    @name =~ /^.*$/
  end

end
end
end
