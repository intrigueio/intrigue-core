module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "A login username identified for a specific website",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/ &&
    details["domain"] =~ /^.*$/ &&
    details["uri"] =~ /^http.*$/
  end

  def enrichment_tasks
    ["enrich/web_account"]
  end


end
end
end
