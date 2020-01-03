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
    name =~ /[\d\.\:]+:\d{1,5}/
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
