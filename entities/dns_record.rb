module Intrigue
module Entity
class DnsRecord < Base

  def metadata
    {
      :type => "DnsRecord",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes[:name] =~ /^.*/
  end

end
end
end
