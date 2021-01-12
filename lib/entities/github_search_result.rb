module Intrigue
module Entity
class GithubSearchResult < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "GithubSearchResult",
      :description => "A Github Search Result"
    }
  end

  def validate_entity
    name.match /^([\.\w\d\ \-\(\)\\\/]+)$/
  end

  def enrichment_tasks
    []
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
