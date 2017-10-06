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
=begin
    if details["lookup_data"]
      if details["lookup_data"].first["lookup_details"]
        d = details["lookup_data"].map do |x|
          x["lookup_details"]["name"] if x["lookup_details"]
        end
        return d.sort.uniq.join(", ")
      end
    else
      ""
    end
=end
  ""
  end

end
end
end
