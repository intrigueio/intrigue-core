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
    "#{details["record_type"]}"
  end

end
end
end
