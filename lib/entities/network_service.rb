module Intrigue
module Entity
class NetworkService < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "NetworkService",
      :description => "A Generic Network Service",
      :user_creatable => true
    }
  end

  def validate_entity
    name.match /[\w\d\.]+:\d{1,5}/
  end

  def detail_string
    "#{details["service"]}"
  end

  def enrichment_tasks
    ["enrich/network_service"]
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end

end
end
end
