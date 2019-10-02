module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "EmailAddress",
      :description => "An Email Address",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,12}/
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

    # Check types we'll check for indicators 
    # of in-scope-ness
    #
    scope_check_entity_types = [
      "Intrigue::Entity::Organization",
      "Intrigue::Entity::DnsRecord",
      "Intrigue::Entity::Domain" 
    ]

    ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES
    ######################################################
    if self.project.seeds
      self.project.seeds.each do |s|
        next unless scope_check_entity_types.include? s.type.to_s
        if self.name =~ /[\s@]#{Regexp.escape(s.name)}/
          #_log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    false
    end

  end


end
end
end
