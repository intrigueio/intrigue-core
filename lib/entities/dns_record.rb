module Intrigue
module Entity
class DnsRecord < Intrigue::Core::Model::Entity

  include Intrigue::Task::Dns

  def self.metadata
    {
      name: "DnsRecord",
      description: "A Dns Record",
      user_creatable: true,
      example: "test.intrigue.io"
    }
  end

  # gets called before entity is created
  def self.transform_before_save(name, details_hash)
    name = SimpleIDN.to_ascii(name)
    return name, details_hash
  end

  def validate_entity
    name.match dns_regex(true)
  end

  def detail_string
    return "" unless details["resolutions"]
    out = "Resolutions: "
    out << details["resolutions"].each.group_by{|k| k["response_type"] }.map{|k,v| "#{k}: #{v.length}"}.join(" | ")
  out
  end

  def enrichment_tasks
    ["enrich/dns_record"]
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={})
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  # if we didnt match the above and we were asked, default to false
  true
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "Domain", name: parse_domain_name(self.name) }
    ]
  end

end
end
end
