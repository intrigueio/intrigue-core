module Intrigue
module Entity
class String < Intrigue::Model::Entity

  def metadata
    {
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
