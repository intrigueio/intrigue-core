module Intrigue
module Entity
class AndroidApp < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "AndroidApp",
      description: "Android Mobile Application",
      user_creatable: true,
      example: "com.example.myapp"
    }
  end

  def validate_entity
    # regex based on app id naming rules as per https://developer.android.com/studio/build/application-id
    name =~ android_app_regex(true)
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
