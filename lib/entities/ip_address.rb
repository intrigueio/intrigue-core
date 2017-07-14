module Intrigue
module Entity
class IpAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "IpAddress",
      :description => "TODO"
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex)

    # warn if they don't exist:
    # details["version"]
  end

  def primary
    false
  end

  def detail_string
    "#{details["os"].to_a.first}"
  end

end
end
end
