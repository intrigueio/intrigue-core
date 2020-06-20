module Intrigue
module Entity
class WebAccount < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "An account identified for a specific hosted service",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w*:\s?\w*$/ &&
    details["username"] =~ /^\w*$/
    details["service"] =~ /^\w*$/
    details["uri"] =~ /^http.*$/
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end

end
end
end
