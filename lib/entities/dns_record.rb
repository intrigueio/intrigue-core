module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "DnsRecord",
      :description => "A Dns Record"
    }
  end

  def validate_entity
    name =~ /\w.*/ #_dns_regex
  end

  def primary
    false
  end

  def detail_string
  end

end
end
end
