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
    name =~ /^[\w\s\d\.\-\_\&\;\:\,\@\(\)\*\/\=]+$/
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

  ###
  ### SCOPING
  ###
  def scoped?(conditions={}) 
    return true if self.seed
    return false if self.hidden # hit our blacklist so definitely false

    # Check types we'll check for indicators 
    # of in-scope-ness
    #
    scope_check_entity_types = [
      "Intrigue::Entity::Organization",
      "Intrigue::Entity::DnsRecord",
      "Intrigue::Entity::Domain" 
    ]

    ### CHECK OUR SEED ENTITIES TO SEE IF THE TEXT MATCHES
    ######################################################
    if self.project.seeds
      self.project.seeds.each do |s|
        next unless scope_check_entity_types.include? s.type.to_s
        if self.name =~ /#{Regexp.escape(s.name)}/i
          #_log "Marking as scoped: SEED ENTITY NAME MATCHED TEXT: #{s["name"]}}"
          return true
        end
      end
    end

  # if we didnt match the above and we were asked, it's still true
  true
  end

end
end
end
