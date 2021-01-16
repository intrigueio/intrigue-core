module Intrigue
module Entity
class IpAddress < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "An IP Address",
      :user_creatable => true,
      :example => "1.1.1.1"
    }
  end

  def validate_entity
    return name.match(ipv4_regex) || name.match(ipv6_regex)
  end

  def detail_string
    out = ""

    if details["geolocation"] && details["geolocation"]["country_code"]
      out << "#{details["geolocation"]["city"]} #{details["geolocation"]["country_code"]} | " 
    end

    if details["ports"] && details["ports"].count > 0
      out << " Open Ports: #{details["ports"].count} | "
    end

    if details["resolutions"]
      out << " PTR: #{details["resolutions"].each.map{|h| h["response_data"] }.join(" | ")}"
    end
    
  out
  end

  def enrichment_tasks
    ["enrich/ip_address"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if scoped
    return true if self.allow_list
    return false if self.deny_list

    # scanner use case 
    # TODO ... this should be handled in the workflow! 
    return true if created_by?("masscan_scan")
    return true if created_by?("nmap_scan")

    # if we have aliases and theyre scoped, we can scope us
    return true if aliases.count > 1 && aliases.select{ |x| x.scoped? }.count > 0

  # if we didnt match the above and we were asked, default to false
  false
  end 

end
end
end
