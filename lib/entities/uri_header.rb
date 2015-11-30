module Intrigue
module Entity
class UriHeader < Intrigue::Model::Entity

  def metadata
    {
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*$/ &&
    @details["content"] =~ /^.*$/
  end

end
end
end
