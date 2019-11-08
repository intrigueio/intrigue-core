module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

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

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden

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
        if self.name =~ /[\s@]#{Regexp.escape(s.name)}/i
          return true
        end
      end
    end
  
    ### CHECK OUR IN-PROJECT ENTITIES TO SEE IF THE NAME MATCHES 
    #######################################################################
    self.project.entities.where(scoped: true, type: scope_check_entity_types ).each do |e|
      # make sure we skip any dns entries that are not fqdns. this will prevent
      # auto-scoping on a single name like "log" or even a number like "1"
      next if (e.type == "DnsRecord" || e.type == "Domain") && e.name.split(".").count == 1
      # Now, check to see if the entity's name matches something in our # whois text, 
      # and especially make sure 
      if "#{details["whois_full_text"]}" =~ /[\s@]#{Regexp.escape(e.name)}/i
        return true
      end
    end



  # if we didnt match the above and we were asked, let's not allow it 
  false
  end


end
end
end
