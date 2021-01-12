module Intrigue
module Entity
class GithubRepository < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "GithubRepository",
      :description => "A Github Repository",
      :user_creatable => true,
      :example => "intrigueio/intrigue-core"
    }
  end

  def validate_entity
    name.match /^[\d\w\-]+\/[\d\w\-]+/
  end

  def scoped?
    return true if scoped
    return true if self.allow_list
    return false if self.deny_list

  true
  end

end
end
end
