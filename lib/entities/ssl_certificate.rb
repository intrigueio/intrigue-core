module Intrigue
module Entity
class SslCertificate < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SslCertificate",
      :description => "An SSL Certificate",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^.*$/
  end

  ###
  # "name" => "#{cert.subject.to_s.split("CN=").last} (#{cert.serial})",
  # "serial" => "#{cert.serial}",
  # "not_before" => "#{cert.not_before}",
  # "not_after" => "#{cert.not_after}",
  # "subject" => "#{cert.subject}",
  # "issuer" => "#{cert.issuer}",
  # "algorithm" => "#{cert.signature_algorithm}",
  # "text" => "#{cert.to_text}" }
  def detail_string
    "#{details["not_after"]} | #{details["subject"]} | #{details["issuer"]}"
  end
  
end
end
end
