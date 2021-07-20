module Intrigue
  module Entity
  class AwsCredential < Intrigue::Core::Model::Entity
  
    def self.metadata
      {
        name: "AwsCredential",
        description: "AWS Credential",
        sensitive: true
      }
    end
  
    def validate_entity
      sensitive_details["aws_access_key_id"] &&
      sensitive_details["aws_secret_access_key"]
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
  