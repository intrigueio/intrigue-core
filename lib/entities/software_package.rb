module Intrigue
module Entity
class SoftwarePackage < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SoftwarePackage",
      :description => "A Detected Software Package",
      :user_creatable => false,
      :example => "Microsoft Office Word 2016"
    }
  end

  def validate_entity
    name =~ /[\&\\s\.\w\d\,\/\\\-]+$/
  end

  def detail_string
    "#{details["origin"]}"
  end

  def scoped?
    return true if self.seed
    return false if self.hidden
  
  true
  end
  
end
end
end
