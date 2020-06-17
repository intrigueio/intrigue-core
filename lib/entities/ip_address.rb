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
    return ( name =~ ipv4_regex || name =~ ipv6_regex )
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
    return true if self.allow_list
    return false if self.deny_list

    # scanner use case 
    #return true if created_by?("masscan_scan")
    #return true if created_by?("nmap_scan")

    # if we have aliases and they're all false, we don't really want this thing
    if self.aliases.count > 0
      return false unless self.aliases.select{ |x| x if 
        (x.kind_of?(Intrigue::Entity::DnsRecord) || x.kind_of?(Intrigue::Entity::Domain)) && !x.hidden }.count > 0
    end

  # if we didnt match the above and we were asked, default to falsse
  true
  end 

end
end
end
