module Intrigue
module Entity
class SnmpServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "SnmpServer",
      :description => "An SNMP Server"
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
