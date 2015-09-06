module Intrigue
module Entity
class DnsRecord < Intrigue::Model::Entity

  def metadata
    {
      :type => "DnsRecord",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^.*/
  end

end
end
end
