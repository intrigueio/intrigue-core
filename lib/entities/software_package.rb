module Intrigue
module Entity
class SoftwarePackage < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "SoftwarePackage",
      description: "A Detected Software Package",
      user_creatable: false,
      example: "Microsoft Office Word 2016"
    }
  end

  def validate_entity
    name.match /^[[[:word:]]\,\.\s\(\)\[\]\®\™]+$/
  end

  def detail_string
    "#{details["origin"]}"
  end

  def scoped?
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  true
  end

end
end
end
