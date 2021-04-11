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
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

    # while it might be nice to scope out stuff on third paries, we still need
    # to keep it in to scan, so we'll need to check scope at that level

  # if we didnt match the above and we were asked, default to true as we'll
  #  we'll want to scope things in before we have a full set of aliases
  true
  end

end
end
end
