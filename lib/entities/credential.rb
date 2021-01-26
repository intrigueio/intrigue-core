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
    out1 = name.match(/^[\w\s\d\.\-\_\&\;\:\,\@]+$/)

    if details 
      out2 = details["username"].to_s.match(/^\w.*$/) &&
      details["password"].to_s.match(/^\w.*$/) &&
      details["uri"].to_s.match(/^http:.*$/)
    end

  out1 && out2 
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
