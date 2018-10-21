module Intrigue
module Entity
class MongoService < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "MongoService",
      :description => "A MongoDB Server",
      :user_creatable => false
    }
  end


  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def enrichment_tasks
    ["enrich/mongo_service"]
  end

end
end
end
