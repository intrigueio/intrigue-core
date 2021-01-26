module Intrigue
module Entity
class IosApp < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "IosApp",
      :description => "IOS Mobile Application",
      :user_creatable => true,
      :example => "example"
    }
  end

  def validate_entity
    name =~ ios_app_regex(true)
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

end
end
end
