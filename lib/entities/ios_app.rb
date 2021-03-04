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
    # only limit is a maximum of 30 characters, as per https://developer.apple.com/app-store/review/guidelines/
    #name =~ /^.{1,30}$/ || name =~ /[\w\s\-\_\.]+/
    name =~ /^[a-zA-Z]+[a-zA-Z0-9_]*\.[a-zA-Z]+[a-zA-Z0-9_]*\.?([a-zA-Z0-9_]*\.*)*$/
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end

end
end
end
