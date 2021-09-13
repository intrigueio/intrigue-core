module Intrigue
module Entity
class GithubRepository < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: "GithubRepository",
      description: "A Github Repository",
      user_creatable: true,
      example: "https://github.com/intrigueio/intrigue-core"
    }
  end

  def enrichment_tasks
    ['enrich/github_repository']
  end


  def validate_entity
    name.match /^https:\/\/github.com\/[\w\-]{1,39}+\/[\w\-]{1,100}+/
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
