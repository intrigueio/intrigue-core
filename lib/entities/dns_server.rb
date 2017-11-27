module Intrigue
module Entity
class DnsServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "DnsServer",
      :description => "A Dns Server"
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
