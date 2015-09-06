module Intrigue
module Entity
class SshServer < Intrigue::Model::Entity

  def metadata
    {
      :type => "SshServer",
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
