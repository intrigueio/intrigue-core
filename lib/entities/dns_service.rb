module Intrigue
module Entity
class DnsService < Intrigue::Entity::NetworkService

  def self.metadata
    {
      :name => "DnsService",
      :description => "A Dns Server",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

end
end
end
