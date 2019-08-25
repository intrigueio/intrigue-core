module Intrigue
module Entity
class GithubAccount < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubAccount",
      :description => "A Github Account",
      :user_creatable => true
    }
  end

  def validate_entity
    name =~ /^[\d\w]+/
  end

  def enrichment_tasks
    ["enrich/github_account"]
  end

end
end
end
