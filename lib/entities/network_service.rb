module Intrigue
module Entity
class NetworkService < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetworkService",
      :description => "A Generic Network Service",
      :user_creatable => false
    }
  end


  def validate_entity
    name =~ /(\w.*):\d{1,5}/ &&
    details["port"].to_s =~ /^\d{1,5}$/ &&
    details["service"].to_s =~ /^\w*$/ &&
    (details["protocol"].to_s == "tcp" || details["protocol"].to_s == "udp")
  end

  def detail_string
    "#{details["service"]}"
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
        next unless scope_check_entities.include? s["type"]
        if out["whois_full_text"] =~ /#{Regexp.escape(s["name"])}/
          _log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    end

    ### CHECK OUR DISCOVERED ENTITIES TO SEE IF THE TEXT MATCHES 
    ############################################################
    self.project.entities.where(scoped: true, type: scope_check_entity_types, hidden: false ).each do |e|

      # make sure we skip any dns entries that are not fqdns. this will prevent
      # auto-scoping on a single name like "log" or even a number like "1"
      next if (e.type == "DnsRecord" || e.type == "Domain") && e.name.split(".").count == 1

      # Now, check to see if the entity's name matches something in our # whois text, 
      # and especially make sure 
      if details["whois_full_text"] =~ /[\s@]#{Regexp.escape(e.name)}/
        _log "Marking as scoped: PROJECT ENTITY MATCHED TEXT: #{e.type}##{e.name}"
        return true
      end

    end

    ### CHECK OUR TRUSTED TASKS: 
    ###  (TODO ... shouldn't this be part of entity creation in the task?)
    ###########################
    if self.created_by?("search_bgp")
      _log "Marking as scoped: CREATED BY SEARCH_BGP"
      return true 
    end
  
    if self.created_by?("import/aws_ipv4_ranges")
      return true 
    end

  # always default to whatever was passed to us (could have been set in the task)
  details["scoped"]
  end

  def enrichment_tasks
    ["enrich/network_service"]
  end


end
end
end
