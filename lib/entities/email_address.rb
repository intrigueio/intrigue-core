module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "EmailAddress",
      :description => "An Email Address",
      :user_creatable => true,
      :example => "no-reply@intrigue.io"
    }
  end

  def validate_entity
    name =~ /[a-zA-Z0-9\.\_\%\+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
  end

  def detail_string
    details["origin"] if details && details["origin"]
  end

  def enrichment_tasks
    ["enrich/email_address"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden

    self.project.seeds.each do |s|
      return true if s.name =~ /#{parse_domain_name(self.name)}/i
    end

    # check hidden on-demand
    return true if self.project.traversable_entity?(parse_domain_name(self.name), "Domain")

  false
  end


end
end
end
