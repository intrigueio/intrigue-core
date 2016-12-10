module Intrigue
module Entity
class PhysicalLocation < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhysicalLocation",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/ #&&
    #@details["latitude"] =~ /^([-+]?\d{1,2}[.]\d+)$/ &&
    #@details["longitude"] =~ /^([-+]?\d{1,3}[.]\d+)$/
  end

end
end
end
