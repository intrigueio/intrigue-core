module Intrigue
module Entity
class EmailAddress < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "EmailAddress",
      description: "An Email Address",
      user_creatable: true,
      example: "no-reply@intrigue.io"
    }
  end

  def validate_entity
    name =~ email_address_regex(true)
  end

  def detail_string
    "#{details["origin"]}" if details 
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)

  false
  end

  def enrichment_tasks
    ["enrich/email_address"]
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "Domain", name:  "#{self.name}".split("@").last }
    ]
  end


end
end
end
