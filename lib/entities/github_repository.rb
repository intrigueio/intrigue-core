module Intrigue
module Entity
class GithubRepository < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubRepository",
      :description => "TODO"
    }
  end

  def validate_entity
    name =~ /^\w.*/ && details["uri"] =~ /^\w.*/
  end

end
end
end
