module Intrigue
module Entity
class GithubRepository < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubRepository",
      :description => "TODO"
    }
  end

  def validate_content
    @name =~ /^.*/ &&
    @uri =~ /^.*/
  end

end
end
end
