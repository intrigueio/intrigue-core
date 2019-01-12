module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "An account identified for a specific hosted service",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w*:\s?\w*$/ &&
    details["username"] =~ /^\w*$/
    details["service"] =~ /^\w*$/
    details["uri"] =~ /^http.*$/
  end

  def enrichment_tasks
    ["enrich/web_account"]
  end


end
end
end
