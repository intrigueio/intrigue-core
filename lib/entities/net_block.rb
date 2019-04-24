module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "A Block of IPs",
      :user_creatable => true
    }
  end

  def validate_entity

    # fail if they don't exist
    name =~ /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/\d{1,2}$/

    # warn if they don't exist:
    # details["organization_reference"]
    # details["whois_full_text"]
  end

  def detail_string
    "#{details["organization_reference"]}"
  end

  def enrichment_tasks
    ["enrich/net_block"]
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
        next unless scope_check_entity_types.include? s["type"]
        if details["whois_full_text"] =~ /[\s@]#{Regexp.escape(s["name"])}/
          #_log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    end

    ### CHECK OUR IN-PROJECT DISCOVERED ENTITIES TO SEE IF THE TEXT MATCHES 
    #######################################################################
    self.project.entities.where(scoped: true, type: scope_check_entity_types, hidden: false ).each do |e|

      # make sure we skip any dns entries that are not fqdns. this will prevent
      # auto-scoping on a single name like "log" or even a number like "1"
      next if (e.type == "DnsRecord" || e.type == "Domain") && e.name.split(".").count == 1

      # Now, check to see if the entity's name matches something in our # whois text, 
      # and especially make sure 
      if details["whois_full_text"] =~ /[\s@]#{Regexp.escape(e.name)}/
        #_log "Marking as scoped: PROJECT ENTITY MATCHED TEXT: #{e.type}##{e.name}"
        return true
      end

    end

  # always default to whatever was passed to us (could have been set in the task)
  scoped
  end


end
end
end
