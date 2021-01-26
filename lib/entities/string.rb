module Intrigue
module Entity
class String < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "String",
      :description => "A Generic Search String",
      :user_creatable => true,
      :example => "Literally any @#$%$!!$^'n old thing!"
    }
  end

  def validate_entity
    name.match /^([\.\w\d\ \-\(\)\\\/]+)$/
  end

  def enrichment_tasks
    ["enrich/string"]
  end

  def scoped?
    return true if scoped
    return true if self.allow_list || self.project.allow_list_entity?(self) 
    return false if self.deny_list || self.project.deny_list_entity?(self)
  
  true
  end

end
end
end
