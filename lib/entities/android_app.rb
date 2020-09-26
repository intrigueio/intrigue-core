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
        name =~ /^\w+\.\w+\.?(\w*\.*)*$/
      end
    
      #def detail_string
      #  "#{details["origin"]}"
      #end
    
      def scoped?
        return true if self.allow_list
        return false if self.deny_list
      
      true
      end
    
    end
    end
    end
    