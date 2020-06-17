module Intrigue
module Entity
class AwsIamAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsIamAccount",
      :description => "An AWS IAM Account",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^(user\/|group\/)[\.\w\-\\\/]+$/ && ["user","group"].include?(details["account_type"]) && details["organization"] != nil
  end

  def detail_string
    "Organization: #{details["organization"]} / Type: #{details["account_type"]} / Name: #{name}" 
  end
 
  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  true # otherwise just default to true
  end

end
end
end
