module Intrigue
module Entity
class IpAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "An IP Address",
      :user_creatable => true
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex)
  end

  def primary
    false
  end

  def detail_string
    details["ports"].count.to_s if details["ports"]
  end

  def enrichment_tasks
    ["enrich/ip_address"]
  end

end
end
end
