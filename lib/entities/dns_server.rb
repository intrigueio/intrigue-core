module Intrigue
module Entity
class DnsServer < Intrigue::Model::Entity

  def metadata
    {
      :type => "DnsServer",
      :required_attributes => ["name"]
    }
  end

  def validate(attributes)
    attributes["name"] =~ /^[a-zA-Z0-9\.].*/
  end

end
end
end
