module Intrigue
module Entity
class FtpServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FtpServer",
      :description => "An FTP Server"
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}\/(udp|tcp)/ && details["port"].to_s =~ /^\d{1,5}$/&& details["port"].to_s =~ /^\d{1,5}$/
  end

  def detail_string
    "#{details["banner"]}"
  end

end
end
end
