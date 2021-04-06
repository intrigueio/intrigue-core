module Intrigue
module Entity
class Mailserver < Intrigue::Core::Model::Entity

  include Intrigue::Task::Dns

  def self.metadata
    {
      name: "Mailserver",
      description: "A Mailserver (MX)",
      user_creatable: true,
      example: "ns1.intrigue.io"
    }
  end

  def validate_entity
    return name.match(ipv4_regex) || name.match(ipv6_regex) || name.match(dns_regex)
  end

  def enrichment_tasks
    ["enrich/mailserver"]
  end

    ###
  ### SCOPING
  ###
  def scoped?(conditions={})
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  # if we didnt match the above and we were asked, it's false
  false
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "DnsRecord", name:  self.name },
      { type_string: "Domain", name:  parse_domain_name(self.name) }
    ]
  end

end
end
end
