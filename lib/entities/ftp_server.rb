module Intrigue
module Entity
class FtpServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FtpServer",
      :description => "Ftp Server"
    }
  end

  def validate_content
    @name =~ /^[a-zA-Z0-9\.\:\/\ ].*/ &&
    @details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
