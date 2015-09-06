module Intrigue
module Entity
class FtpServer < Intrigue::Model::Entity

  def metadata
    {
      :type => "FtpServer",
      :required_attributes => ["name","port"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^[a-zA-Z0-9\.\:\/\ ].*/ &&
    attributes["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
