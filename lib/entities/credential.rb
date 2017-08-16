module Intrigue
module Entity
class Credential < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Credential",
      :description => "Login Credential"
    }
  end

  def validate_entity
    name =~ /^\w.*/ &&
    details["username"].to_s =~ /^\w.*$/ &&
    details["password"].to_s =~ /^\w.*$/ &&
    details["uri"].to_s =~ /^http:.*$/
  end

end
end
end
