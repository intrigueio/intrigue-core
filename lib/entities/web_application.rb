module Intrigue
module Entity
class WebApplication < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "WebApplication",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/
  end

end
end
end
