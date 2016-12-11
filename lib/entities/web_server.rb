module Intrigue
module Entity
class WebServer < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebServer",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
