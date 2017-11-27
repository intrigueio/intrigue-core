module Intrigue
module Entity
class AwsCredential < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "AwsCredential",
      :description => "AWS Credential in the format... AccessID:SecretKey"
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
    name =~ /.*\*\*\*$/ &&
    details["hidden_access_id"] &&
    details["hidden_secret_key"]
  end


end
end
end
