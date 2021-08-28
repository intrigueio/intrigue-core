module Intrigue
module Entity
class SslCertificate < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "SslCertificate",
      description: "An SSL Certificate",
      user_creatable: false,
      example: "intrigue.io (311448f91da5668ce8e4c1a7b49615e83f19c14ce7f7dd4088f32a6f97f56707)"
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
  # "fingerprint_sha256" => "#{cert_sha256_fingerprint}",
  # "text": "#{cert.to_text}" }
  def detail_string
    "#{details["not_after"]} | #{details["subject"]} | #{details["issuer"]}"
  end

  ###
  ### SCOPING
  ###
  def scoped?(conditions={})
    return scoped unless scoped.nil?
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
      { type_string: "#{self.type_string}", name: "#{self.name}" },
      { type_string: "DnsRecord", name: hostname },
      { type_string: "Domain", name:  parse_domain_name(hostname) }
    ]
  end


end
end
end
