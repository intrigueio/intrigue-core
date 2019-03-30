module Intrigue
module Entity
class Nameserver < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Nameserver",
      :description => "A DNS Nameserver",
      :user_creatable => true
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex || name =~ _dns_regex )
  end

  def enrichment_tasks
    ["enrich/nameserver"]
  end

end
end
end
