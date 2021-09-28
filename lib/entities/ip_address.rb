module Intrigue
module Entity
class IpAddress < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "IpAddress",
      description: "An IP Address",
      user_creatable: true,
      example: "1.1.1.1"
    }
  end

  def validate_entity
    scan_internal = (Intrigue::Core::System::Config.config["scan_internal_ips"] == true ) ? true : false
    
    # check if valid ipv4 or ipv6
    unless name.match(ipv4_regex) || name.match(ipv6_regex)
      return false
    end
    
    # check if localhost
    if name.match(/^127(?:\.[0-9]+){0,2}\.[0-9]+$|^(?:0*\:)*?:?0*1$/)
      return false
    end
    
    # check if we should scan internal
    # https://docs.microfocus.com/NNMi/10.30/Content/Administer/NNMi_Deployment/Advanced_Configurations/Private_IP_Address_Range.htm
    unless scan_internal
      # check if we match 172.16.x.x
      return false if name.match(/(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)/)

      # check if we match 10.x.x.x
      return false if name.match(/(^10\.)/)

      # check if we match 192.168.x.x
      return false if name.match(/(^192\.168\.)/)

      # fc00::/7 address block = RFC 4193 Unique Local Addresses (ULA)
      return false if name.match(/(^fc00\:)/)

      # fec0::/10 address block = deprecated (RFC 3879)
      return false if name.match(/(^fec0\:)/)
    end

    return true
  end

  def detail_string
    out = ""

    if details["network.name"]
      out << "#{details["network.name"]} | "
    end

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
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

    # while it might be nice to scope out stuff on third parties, we still need
    # to keep it in to scan, so we'll need to check scope at that level

  # if we didnt match the above and we were asked, default to true as we'll
  #  we'll want to scope things in before we have a full set of aliases
  true
  end

end
end
end
