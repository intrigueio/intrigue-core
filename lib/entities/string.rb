module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "String",
      :description => "TODO"
    }
  end

  def validate
    puts "calling validate"
    @name =~ /^.*$/
  end

end
end
end
