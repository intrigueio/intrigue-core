module Intrigue
module Entity
class SmtpServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SmtpServer",
      :description => "An SMTP Server"
    }
  end

  def validate_entity
    (name =~ _v4_regex || name =~ _v6_regex || name == _dns_regex) && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
