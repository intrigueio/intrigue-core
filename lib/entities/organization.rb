module Intrigue
module Entity
class Organization < Intrigue::Model::Entity

  def self.metadata
    {
      :name => "Organization",
      :description => "An organization",
      :user_creatable => true,
      :example => "Intrigue Corporation"
    }
  end

  def validate_entity
    name =~ /^[\w\s\d\.\-\_\&\;\:\,\@]{3,}$/
  end

  def enrichment_tasks
    ["enrich/organization"]
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list
  
  false
  end

end
end
end
