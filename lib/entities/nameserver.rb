module Intrigue
module Entity
class Nameserver < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Nameserver",
      :description => "A DNS Nameserver",
      :user_creatable => true,
      :example => "ns1.intrigue.io"
    }
  end

  def validate_entity
    return ( name =~ ipv4_regex || name =~ ipv6_regex || name =~ dns_regex )
  end

  def enrichment_tasks
    ["enrich/nameserver"]
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
      "Intrigue::Entity::Domain" ]

    ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES
    ######################################################
    if self.project.seeds
      self.project.seeds.each do |s|
        next unless scope_check_entity_types.include? s.type.to_s
        if details["whois_full_text"] =~ /#{Regexp.escape(s.name)}/
          #_log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    end

  # always default to whatever was passed to us (could have been set in the task)
  scoped
  end

end
end
end
