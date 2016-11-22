module Intrigue
module Entity
class GithubUser < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubUser",
      :description => "TODO"
    }
  end


  def validate
    @name =~ /^.*/ &&
    @uri =~ /^.*/
  end

end
end
end
