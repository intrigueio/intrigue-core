module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "TODO"
    }
  end


  def validate_entity

    # required:
    name =~ /^\w.*$/
    # suggested:
    # details["organization_reference"]
  end

  def detail_string
    "Ref: #{details["organization_reference"]}"
  end

end
end
end
