module Intrigue
module Entity
class Credential < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Credential",
      :description => "Login Credential",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^[\w\s\d\.\-\_\&\;\:\,\@]+$/ &&
    details["username"].to_s =~ /^\w.*$/ &&
    details["password"].to_s =~ /^\w.*$/ &&
    details["uri"].to_s =~ /^http:.*$/
  end

  def scoped?
    return true if self.seed
    return false if self.hidden
  true # otherwise just default to true
  end

end
end
end
