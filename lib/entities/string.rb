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
    #name =~ /^([\.\w\d\ \-\(\)\\\/]+)$/
    name =~ /.*/
  end

  def enrichment_tasks
    ["enrich/string"]
  end

  def scoped?
    return true if self.allow_list
    return false if self.deny_list

  true
  end


end
end
end
