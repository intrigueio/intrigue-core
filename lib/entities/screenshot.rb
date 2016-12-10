module Intrigue
module Entity
class Screenshot < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Screenshot",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*$/ # XXX - too loose
    #@details[:file] =~ /^.*$/ # XXX - too loose
  end

end
end
end
