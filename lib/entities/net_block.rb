module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "A Block of IPs"
    }
  end


  def validate_entity

    # fail if they don't exist
    name =~ /^\w.*$/

    # warn if they don't exist:
    # details["organization_reference"]
    # details["whois_full_text"]
  end

  def detail_string
    "#{details["organization_reference"]}"
  end

end
end
end
