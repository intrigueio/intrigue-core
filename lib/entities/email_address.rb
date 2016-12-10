module Intrigue
module Entity
class EmailAddress < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "EmailAddress",
      :description => "TODO"
    }
  end


  def validate_content
    @name =~ /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/
  end

end
end
end
