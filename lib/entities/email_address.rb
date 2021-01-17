module Intrigue
module Entity
class EmailAddress < Intrigue::Core::Model::Entity



  def self.metadata
    {
      :name => "EmailAddress",
      :description => "An Email Address",
      :user_creatable => true,
      :example => "no-reply@intrigue.io"
    }
  end

  def validate_entity
    name.match /[a-zA-Z0-9\.\_\%\+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
  end

  def detail_string
    details["origin"] if details && details["origin"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if scoped
    return true if self.allow_list
    return false if self.deny_list

    # Check the domain
    domain_name = self.name.split("@").last
    return true if self.project.allow_list_entity?("Domain", domain_name)

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
