module Intrigue
module Entity
class SmtpService < Intrigue::Entity::NetworkService

  def self.metadata
    {
      :name => "SmtpService",
      :description => "An SMTP Server",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def enrichment_tasks
    ["enrich/smtp_service"]
  end


end
end
end
