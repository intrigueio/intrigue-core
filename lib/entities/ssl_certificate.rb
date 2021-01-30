module Intrigue
module Entity
class SslCertificate < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "SslCertificate",
      description: "An SSL Certificate",
      user_creatable: false,
      example: "test.intrigue.io (3695285271625093099202351562148679716)"
    }
  end

  def validate_entity
    name.match /^[\w\s\d\.\-\_\&\;\:\,\@\(\)\*\/\?\=]+$/
  end

  ###
  # "name": "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
  # "serial": "#{cert.serial}",
  # "not_before": "#{cert.not_before}",
  # "not_after": "#{cert.not_after}",
  # "subject": "#{cert.subject}",
  # "issuer": "#{cert.issuer}",
  # "algorithm": "#{cert.signature_algorithm}",
  # "text": "#{cert.to_text}" }
  def detail_string
    "#{details["not_after"]} | #{details["subject"]} | #{details["issuer"]}"
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

  def enrichment_tasks
    ["enrich/ssl_certificate"]
  end


  def scope_verification_list
    hostname = "#{self.name}".split(" ").first.gsub("*.","")
    [
      { type_string: self.type_string, name: self.name },
      { type_string: "DnsRecord", name: hostname },
      { type_string: "Domain", name:  parse_domain_name(hostname) }
    ]
  end


end
end
end
