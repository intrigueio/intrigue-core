module Intrigue
module Entity
class PhysicalLocation < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/ #&&
    #@details["latitude"] =~ /^([-+]?\d{1,2}[.]\d+)$/ &&
    #@details["longitude"] =~ /^([-+]?\d{1,3}[.]\d+)$/
  end

end
end
end
