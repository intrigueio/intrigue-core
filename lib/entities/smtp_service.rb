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

end
end
end
