module Intrigue
module Entity
class FingerServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FingerServer",
      :description => "Finger Server"
    }
  end

  def validate_content
    @name =~ /^[a-zA-Z0-9\.\:\/\ ].*/ &&
    @details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
