module Intrigue
module Entity
class HttpHeader < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "HttpHeader",
      :description => "TODO"
    }
  end

  def validate_entity
    name =~ /^\w.*$/ && details["content"] =~ /^.*$/
  end

end
end
end
