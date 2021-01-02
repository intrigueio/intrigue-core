module Intrigue
module Entity
class Credential < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "Credential",
      :description => "Login Credential",
      :user_creatable => false
    }
  end

  def validate_entity
    out1 = name =~ /^[\w\s\d\.\-\_\&\;\:\,\@]+$/ 

    if details 
      out2 = details["username"].to_s =~ /^\w.*$/ &&
      details["password"].to_s =~ /^\w.*$/ &&
      details["uri"].to_s =~ /^http:.*$/
    end

  out1 && out2 
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  true # otherwise just default to true
  end

end
end
end
