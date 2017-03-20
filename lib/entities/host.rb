module Intrigue
module Entity
class Host < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Host",
      :description => "TODO"
    }
  end

  def validate_entity
    return (name =~ _v4_regex || name =~ _v6_regex || name =~ _dns_regex)
  end

  def unique_names
    x = [name]
    x.concat(details["dns_names"]) if details["dns_names"]
    x.concat(details["ip_addresses"]) if details["ip_addresses"]

    x.sort.uniq
  end


end
end
end
