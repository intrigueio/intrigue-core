module Intrigue
module Entity
class GithubUser < Intrigue::Model::Entity

  def metadata
    {
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
