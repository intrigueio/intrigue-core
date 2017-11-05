module Intrigue
module Entity
class SshServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SshServer",
      :description => "A SSH Server"
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
