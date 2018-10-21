module Intrigue
module Entity
class PhysicalLocation < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhysicalLocation",
      :description => "A Physical Location",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/ #&&
    #details["latitude"] =~ /^([-+]?\d{1,2}[.]\d+)$/ &&
    #details["longitude"] =~ /^([-+]?\d{1,3}[.]\d+)$/
  end

  def enrichment_tasks
      ["enrich/physical_location"]
  end


end
end
end
