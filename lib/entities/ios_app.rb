module Intrigue
    module Entity
    class IOSApp < Intrigue::Core::Model::Entity
    
      def self.metadata
        {
          :name => "IOSApp",
          :description => "IOS Mobile Application",
          :user_creatable => true,
          :example => "example"
        }
      end
    
      def validate_entity
        name =~ /^[a-zA-Z0-9\-]+$/
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
    