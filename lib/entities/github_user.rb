module Intrigue
module Entity
class GithubUser < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubUser",
      :description => "TODO"
    }
  end

  def validate_entity
    name =~ /^\w.*/ && details["uri"] =~ /^.*/
  end

end
end
end
