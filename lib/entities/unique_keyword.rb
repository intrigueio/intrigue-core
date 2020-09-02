module Intrigue
  module Entity
  class UniqueKeyword < Intrigue::Core::Model::Entity
  
    def self.metadata
      {
        :name => "UniqueKeyword",
        :description => "Unique Keyword - globally unique keyword that can be reliably searched",
        :user_creatable => true,
        :example => "Intrigue.io"
      }
    end
  
    def validate_entity
      name =~ /^([\w\d\ \-\(\)\\\/]+)$/
    end

    def scoped?
      return true if self.allow_list
      return false if self.deny_list
    
    true
    end
  
    #def enrichment_tasks
    #  ["enrich/string"]
    #end

end
end
end
