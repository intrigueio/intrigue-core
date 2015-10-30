module Intrigue
module Entity
class NetBlock < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/
  end

end
end
end
