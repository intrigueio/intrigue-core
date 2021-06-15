module Intrigue
module Entity
class AzureBlob < Intrigue::Core::Model::Entity

  def self.metadata
    {
      name: 'AzureBlob',
      description: 'An Azure Blob',
      user_creatable: true,
      example: 'https://example.blob.core.windows.net'
    }
  end

  def validate_entity
     name.match(/\.blob\.core\.windows\.net/)
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/azure_blob"]
  end

  def scoped?(conditions={})
    return scoped unless scoped.nil?
    return true if self.allow_list || self.project.allow_list_entity?(self)
    return false if self.deny_list || self.project.deny_list_entity?(self)

  true # otherwise just default to true
  end

end
end
end
