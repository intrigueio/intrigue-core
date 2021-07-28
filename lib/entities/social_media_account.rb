module Intrigue
  module Entity
    class SocialMediaAccount < Intrigue::Core::Model::Entity
    
      def self.metadata
        {
          name: "SocialMediaAccount",
          description: "Social media account",
          user_creatable: true,
          example: "intrigueio"
        }
      end
    
      def validate_entity
        name.match /.*/
      end
    
      def enrichment_tasks
        ["enrich/twitter_account"]
      end
    
      def scoped?
        return scoped unless scoped.nil?
        return true if self.allow_list || self.project.allow_list_entity?(self)
        return false if self.deny_list || self.project.deny_list_entity?(self)
    
      true
      end
  
    end
  end
end