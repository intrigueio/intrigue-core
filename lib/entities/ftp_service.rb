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
    # TODO - this doesnt really work
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def detail_string
    details["banner"][0..79].tr("\n","").tr("\r","") if details && details["banner"]
  end

  def enrichment_tasks
    ["enrich/ftp_service", "ftp_enumerate"]
  end


end
end
end
