module Intrigue
module Entity
class GithubRepository < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubRepository",
      :description => "A Github Repository",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*/ && details["uri"] =~ /^\w.*/
  end

  def enrichment_tasks
    ["enrich/github_repository"]
  end

end
end
end
