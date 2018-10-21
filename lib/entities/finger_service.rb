module Intrigue
module Entity
class FingerService < Intrigue::Entity::NetworkService

  def self.metadata
    {
      :name => "FingerService",
      :description => "A Finger Server",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def enrichment_tasks
    ["enrich/finger_service"]
  end

end
end
end
