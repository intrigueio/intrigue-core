module Intrigue
module Entity
class SoftwarePackage < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SoftwarePackage",
      :description => "A Software Package, identified through metadata"
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def detail_string
    "#{details["extracted_from"]}"
  end

end
end
end
