module Intrigue
  module Entity
  class UniqueKeyword < Intrigue::Core::Model::Entity
  
    def self.metadata
      {
        name: "UniqueKeyword",
        description: "A globally unique keyword that can be reliably searched",
        user_creatable: true,
        example: "Intrigue.io"
      }
    end
  
    def validate_entity
      name.match /^([\,\w\d\ \-\(\)\\\/]+)$/
    end

    def scoped?
      return true if scoped
      return true if self.allow_list
      return false if self.deny_list
    
    true
    end
  
end
end
end
