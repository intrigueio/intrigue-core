module Intrigue
module Entity
class ApiEndpoint < Intrigue::Core::Model::Entity
  
  def self.metadata
    {
      name: "ApiEndpoint",
      description: "A HTTP based api endpoint",
      user_creatable: true,
      example: "https://app.intrigue.io/api"
    }
  end

  def validate_entity
    name.match /^https?:\/\/.*$/
  end

  def detail_string
    
    # create fingerprint
    if details["fingerprint"]
      fingerprint_array = details["fingerprint"].map do |x| 
        "#{x['vendor']} #{x['product'] unless x['vendor'] == x['product']} #{x['version']}".strip
      end
      out = "Fingerprint: #{fingerprint_array.sort.uniq.join("; ")}" if details["fingerprint"]
    else
      out = ""
    end

    if details["title"]
      out << " | " if out.length > 0
      out << " Title: #{details["title"]}" 
    end

  out
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)

  # if we didnt match the above and we were asked, it's still true
  true
  end

  def enrichment_tasks
    ["enrich/api_endpoint"]
  end

  def scope_verification_list
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "DnsRecord", name:  URI.parse(self.name).host },
      { type_string: "Domain", name:  parse_domain_name(URI.parse(self.name).host) }
    ]
  end

end
end
end
