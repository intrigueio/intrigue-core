module Intrigue
module Entity
class GithubAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubAccount",
      :description => "A Github Account",
      :user_creatable => true,
      :example => "intrigueio"
    }
  end

  def validate_entity
    name =~ /^[\d\w]+/
  end

  def enrichment_tasks
    ["enrich/github_account"]
  end

  def scoped?
    return true if self.seed
    return false if self.hidden
  
  true
  end

end
end
end
