module Intrigue
module Entity
class AwsCredential < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AwsCredential",
      description: "AWS Credential in the format... AccessID:SecretKey",
      user_creatable: false,
      example: "AKIAIOSFODNN7EXAMPLE:wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
  end

  def transform!
    # We'll want to obfuscate our name
    new_name = "#{name[0..3]}****"

    # .. and we'll need to split into an access_id and a secret_key
    set_details({ "name" => new_name,
                  "hidden_original" => details["hidden_original"],
                  "hidden_access_id" => details["hidden_original"].split(":").first,
                  "hidden_secret_key" => details["hidden_original"].split(":").last })

    # Save the new name
    self.set(:name => new_name) && save

  true
  end

  def validate_entity
    name.match(/.*\*\*\*$/) &&
    details["hidden_access_id"] &&
    details["hidden_secret_key"]
  end

  def scoped?
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)
  true # otherwise just default to true
  end

end
end
end
