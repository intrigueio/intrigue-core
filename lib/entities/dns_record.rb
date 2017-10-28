module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A DnsRecord"
    }
  end

  def validate_entity
    return (name =~ _dns_regex)
  end

  def primary
    false
  end

  def detail_string
    if details["lookup_data"]
      details["lookup_data"].map{|x| x["name"] if x }.sort.uniq.join(", ")
    else
      ""
    end
  end

end
end
end
