module Intrigue
module Entity
class IpAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "An IP Address",
      :user_creatable => true,
      :example => "1.1.1.1"
    }
  end

  def validate_entity
    return ( name =~ ipv4_regex  || name =~ ipv6_regex )
  end

  def detail_string
    out = ""
    out << "#{details["geolocation"]["city_name"]} #{details["geolocation"]["country_name"]} | " if details["geolocation"]
    out << "#{details["ports"].count.to_s} Ports " if details["ports"]
    out << "| DNS: #{details["dns_entries"].each.map{|h| h["response_data"] }.join(" | ")}" if details["dns_entries"]
  out
  end

  def enrichment_tasks
    ["enrich/ip_address"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return false if self.hidden

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
        next unless scope_check_entity_types.include?(s.type.to_s) 
        
        # only if it's a domain
        if s["type"] == "Intrigue::Entity::Domain" # try the basename )
          base_name = s["name"].split(".").first # x.com -> x
          return true if (details["whois_full_text"] =~ /#{Regexp.escape(base_name)}/)
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

  # if we didnt match the above and we were asked, it's still true 
  true
  end 

end
end
end
