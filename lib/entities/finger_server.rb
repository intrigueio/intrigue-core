module Intrigue
module Entity
class FingerServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "FingerServer",
      :description => "A Finger Server"
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}\/(udp|tcp)/ && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
