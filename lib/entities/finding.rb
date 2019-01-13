module Intrigue
module Entity
class Finding < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Finding",
      :description => "Vulnerability or security-related finding",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*$/
  end

  def enrichment_tasks
    ["enrich/finding"]
  end

end
end
end
