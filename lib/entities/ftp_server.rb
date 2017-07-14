module Intrigue
module Entity
class FtpServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FtpServer",
      :description => "Ftp Server"
    }
  end

  def validate_entity
    (name =~ _v4_regex || name =~ _v6_regex || name == _dns_regex) && details["port"].to_s =~ /^\d{1,5}$/
  end

  def detail_string
    "#{details["banner"]}"
  end

end
end
end
