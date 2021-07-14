module Intrigue
module Entity
class GithubAccount < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "GithubAccount",
      description: "A Github Account",
      user_creatable: true,
      example: "intrigueio"
    }
  end

  def validate_entity
    name.match /^[\d\w]+/
  end

  def enrichment_tasks
    ['enrich/github_account', 'gather_github_repositories'] 
  end

  def scoped?
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  true
  end

end
end
end
