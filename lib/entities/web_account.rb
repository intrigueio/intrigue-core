module Intrigue
module Entity
class WebAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebAccount",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/ &&
    @details["domain"] =~ /^.*$/ &&
    @details["uri"] =~ /^http.*$/
  end

end
end
end
