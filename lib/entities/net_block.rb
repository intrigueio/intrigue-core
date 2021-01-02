module Intrigue
module Entity
class NetBlock < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "A Block of IPs",
      :user_creatable => true,
      :example => "1.1.1.1/24"
    }
  end

  def validate_entity
    name =~ netblock_regex || name =~ netblock_regex_two
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
    return true if self.allow_list
    return false if self.deny_list

    our_ip = self.name.split("/").first
    our_route = self.name.split("/").last.to_i
    whois_text = "#{details["whois_full_text"]}"

    # Check for case where we're just one ip address
    #if our_ip =~ ipv6_regex && our_route == 64
    #  return true # ipv6 single ip
    #elsif our_ip =~ ipv4_regex && our_route == 32
    #  return true # ipv4 single ip
    #end

    ###
    ### First, check our text to see if there's a more specific route in here, 
    ###  and if so, not ours.
    #########################################################################
    match_captures = whois_text.scan(netblock_regex)
    match_captures.each do |capture|
      
      ip = capture.first.split("/").first
      route = capture.last
      
      # compare each to our lookup stringg
      if ip == our_ip && route > our_route
        return false
      end

    end

    # Check types we'll check for indicators 
    # of in-scope-ness
    #
    scope_check_entity_types = [
      "Intrigue::Entity::Organization",
      "Intrigue::Entity::DnsRecord",
      "Intrigue::Entity::Domain" 
    ]

    ### Now check our seed entities for a match
    ######################################################
    if self.project.seeds
      self.project.seeds.each do |s|
        next unless scope_check_entity_types.include? "#{s.type}"
        if whois_text =~ /@#{Regexp.escape(s.name)}/i
          
          # Log our scope change
          log_string = " - [#{s.project.name}] Entity #{s.type} #{s.name} set scoped on #{self.name} to true, reason: whois text matched #{s.name}"
          Intrigue::Core::Model::ScopingLog.log log_string

          return true
        end
      end
    end

    ### And now, let's check our corpus of already-scoped stuff from this run 
    #############################################################################
    #self.project.entities.where(scoped: true, type: scope_check_entity_types ).each do |e|
    #  # make sure we skip any dns entries that are not fqdns. this will prevent
    #  # auto-scoping on a single name like "log" or even a number like "1"
    #  next if (e.type == "DnsRecord" || e.type == "Domain") && e.name.split(".").count == 1
    #  # Now, check to see if the entity's name matches something in our # whois text, 
    #  # and especially make sure 
    #  if whois_text =~ /@#{Regexp.escape(e.name)}/i
    #
    #    # Log our scope change
    #    log_string = " - [#{e.project.name}] Entity #{e.type} #{e.name} set scoped on #{self.name} to true, reason: whois text matched #{e.name}"
    #    Intrigue::Core::Model::ScopingLog.log log_string
    #
    #    return true
    #  end
    #end

    # now check more edge cases

    ### CHECK OUR IN-PROJECT ENTITIES TO SEE IF THE ORG NAME MATCHES 
    #######################################################################
    #if details["organization"] || details["organization_name"]
    #  self.project.entities.where(scoped: true, type: scope_check_entity_types ).each do |e|
    #    # make sure we skip any dns entries that are not fqdns. this will prevent
    #    # auto-scoping on a single name like "log" or "www" or even a number like "1"
    #    next if (e.type == "DnsRecord" || e.type == "Domain") && e.name.split(".").count == 1
    #    # Now, check to see if the entity's name matches something in our # whois text, 
    #    # and especially make sure 
    #    if (details["organization"] =~ /@#{Regexp.escape(e.name)}/i) || 
    #        (details["organization_name"] =~ /@#{Regexp.escape(e.name)}/i)
    #
    #        # Log our scope change
    #        log_string = " - [#{e.project.name}] Entity #{e.type} #{e.name} set scoped on #{self.name} to true, reason: org name matched #{e.name}"
    #        Intrigue::Core::Model::ScopingLog.log log_string
    #
    #      return true
    #    end
    #  end
    #else
    #  if (!whois_text && details["cidr"].to_i > 23)
    #
    #    # Log our scope change
    #    log_string = " - [#{e.project.name}] Entity #{e.type} #{e.name} set scoped on #{self.name} to true, reason: missing whois text and small cidr"
    #    Intrigue::Core::Model::ScopingLog.log log_string
    #    
    #    return true 
    #  end
    #end

  # if we didnt match the above and we were asked, it's false 
  false
  end


end
end
end
