module Intrigue
module Entity
class AwsIamAccount < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AwsIamAccount",
      description: "An AWS IAM Account",
      user_creatable: false,
      example: "testtesttest"
    }
  end

  def validate_entity
    name.match(/^(user\/|group\/)[\.\w\-\\\/]+$/) && ["user","group"].include?(details["account_type"]) && details["organization"] != nil
  end

  def detail_string
    "Organization: #{details["organization"]} / Type: #{details["account_type"]} / Name: #{name}" 
  end
 
  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  true # otherwise just default to true
  end

end
end
end
