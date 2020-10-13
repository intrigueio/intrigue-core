module Intrigue
    module Entity
    class AndroidApp < Intrigue::Core::Model::Entity
    
      def self.metadata
        {
          :name => "AndroidApp",
          :description => "Android Mobile Application",
          :user_creatable => true,
          :example => "com.example.myapp"
        }
      end
    
      def validate_entity
        # regex based on app id naming rules as per https://developer.android.com/studio/build/application-id
        name =~ /^[a-zA-Z]+[a-zA-Z0-9_]*\.[a-zA-Z]+[a-zA-Z0-9_]*\.?([a-zA-Z0-9_]*\.*)*$/
        #name =~ /[\w\-\_\s]+/
      end
    
      def scoped?
        return true if self.allow_list
        return false if self.deny_list
      
      true
      end
    
    end
    end
    end
    