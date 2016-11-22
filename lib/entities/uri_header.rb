module Intrigue
module Entity
class UriHeader < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "UriHeader",
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
