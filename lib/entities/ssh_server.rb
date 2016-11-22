module Intrigue
module Entity
class SshServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SshServer",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^[a-zA-Z0-9\.\:\/\ ].*/ &&
    @details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
