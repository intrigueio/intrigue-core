module Intrigue
module Entity
class Organization < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "Organization",
      :description => "An organization",
      :user_creatable => true,
      :example => "Intrigue Corporation"
    }
  end

  def validate_entity
    name.match /^[\w\s\d\.\-\_\&\;\:\,\@]{3,}$/
  end

  def enrichment_tasks
    ["enrich/organization"]
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  false
  end

end
end
end
