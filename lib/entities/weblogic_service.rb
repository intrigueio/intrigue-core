module Intrigue
module Entity
class WeblogicService < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WeblogicService",
      :description => "A Weblogic Service",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /(\w.*):\d{1,5}/ && details["port"].to_s =~ /^\d{1,5}$/
  end

  def enrichment_tasks
    ["enrich/weblogic_service"]
  end


end
end
end
