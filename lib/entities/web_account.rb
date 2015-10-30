module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end

  def validate
    @name =~ /^.*$/ &&
    @details["domain"] =~ /^.*$/ &&
    @details["uri"] =~ /^http.*$/
  end

end
end
end
