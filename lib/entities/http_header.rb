module Intrigue
module Entity
class HttpHeader < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "HttpHeader",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/ &&
    @details["content"] =~ /^.*$/
  end

end
end
end
