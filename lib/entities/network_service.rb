module Intrigue
module Entity
class NetworkService < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetworkService",
      :description => "A Generic Network Service",
      :user_creatable => false
    }
  end


  def validate_entity
    name =~ /(\w.*):\d{1,5}/ &&
    details["port"].to_s =~ /^\d{1,5}$/ &&
    details["service"].to_s =~ /^\w*$/ &&
    (details["protocol"].to_s == "tcp" || details["protocol"].to_s == "udp")
  end

  def detail_string
    "#{details["service"]}"
  end

  def enrichment_tasks
    ["enrich/network_service"]
  end


end
end
end
