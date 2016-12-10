module Intrigue
module Entity
class SoftwarePackage < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SoftwarePackage",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
