module Intrigue
module Entity
class NetworkService < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "NetworkService",
      description: "A Generic Network Service",
      user_creatable: true,
      example: "1.1.1.1:80/tcp"
    }
  end

  def validate_entity
    name.match network_service_regex(true)
  end

  def detail_string

    out = ""

    # create fingerprint details string
    out = "#{short_fingerprint_string(details["fingerprint"])} | " if details["fingerprint"]

    out << "Port: #{details["service"]}"
  end

  def enrichment_tasks
    ["enrich/network_service"]
  end

  def scoped?
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

    # only scope in stuff that's not hidden
    return false if self.hidden

  true
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "IpAddress", name: self.name.split(":").first }
    ]
  end

end
end
end
