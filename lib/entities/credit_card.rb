module Intrigue
  module Entity
  class CreditCard < Intrigue::Core::Model::Entity
  
    def self.metadata
      {
        name: "CreditCard",
        description: "A Credit Card",
        user_creatable: false, 
        example: "4111111111111111"
      }
    end
  
    def validate_entity
      name =~ credit_card_regex(true)
    end
  
    def detail_string
      "*************#{name[-4..-1]}" 
    end
   
    def scoped?
      return true if scoped
      return true if self.allow_list || self.project.allow_list_entity?(self) 
      return false if self.deny_list || self.project.deny_list_entity?(self)
    true # otherwise just default to true
    end
  
  end
  end
  end
  