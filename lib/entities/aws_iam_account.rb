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
 
end
end
end
