module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "NetBlock",
      :description => "TODO"
    }
  end


  def validate

    # required:
    @name =~ /^.*$/

    # suggested:
    # @details["organization_reference"]

  end

end
end
end
