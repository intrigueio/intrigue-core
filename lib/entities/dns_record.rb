module Intrigue
module Entity
class DnsRecord < Intrigue::Core::Model::Entity
  
  include Intrigue::Task::Dns

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record",
      :user_creatable => true,
      :example => "test.intrigue.io"
    }
  end

  def validate_entity
    name.match dns_regex
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
    return true if scoped
    return true if self.allow_list
    return false if self.deny_list

  # if we didnt match the above and we were asked, default to false
  false
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
