module Intrigue
module Entity
class GithubUser < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "GithubUser",
      :description => "A Github User",
      :user_creatable => false
    }
  end

  def validate_entity
    name =~ /^\w.*/ && details["uri"] =~ /^.*/
  end

  def enrichment_tasks
    ["enrich/github_user"]
  end

end
end
end
