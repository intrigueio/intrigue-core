module Intrigue
module Entity
class GithubRepository < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubRepository",
      :description => "A Github Repository",
      :user_creatable => true,
      :example => "intrigueio/intrigue-core"
    }
  end

  def validate_entity
    name =~ /^[\d\w]+\/[\d\w]+/
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end

end
end
end
