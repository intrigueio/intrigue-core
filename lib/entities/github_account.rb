module Intrigue
module Entity
class GithubAccount < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "GithubAccount",
      :description => "A Github Account",
      :user_creatable => true,
      :example => "intrigueio"
    }
  end

  def validate_entity
    name.match /^[\d\w]+/
  end

  def enrichment_tasks
    ["enrich/github_account"]
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  true
  end

end
end
end
