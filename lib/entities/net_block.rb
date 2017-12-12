module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "A Block of IPs",
      :user_creatable => true
    }
  end


  def validate_entity

    # fail if they don't exist
    name =~ /^\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\/\d{1,2}$/

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
