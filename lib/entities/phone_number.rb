module Intrigue
module Entity
class PhoneNumber < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "PhoneNumber",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/
  end

end
end
end
