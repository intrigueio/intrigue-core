module Intrigue
module Entity
class FtpService < Intrigue::Entity::NetworkService

  def self.metadata
    {
      :name => "FtpService",
      :description => "An FTP Server",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def detail_string
    details["banner"] if details && details["banner"]
  end

end
end
end
