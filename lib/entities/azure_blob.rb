module Intrigue
module Entity
class AzureBlob < Intrigue::Core::Model::Entity

  def self.metadata
    {
      :name => "AzureBLOB",
      :description => "Azure Blob storage",
      :user_creatable => true,
      :example => "https://azure.microsoft.com/en-us/services/storage/blobs/"
    }
  end

  def validate_entity
    name =~ /.blob.core.windows.net/
  end

  def detail_string
    "File count: #{details["contents"].count}" if details["contents"]
  end

  def enrichment_tasks
    ["enrich/azure_blob"]
  end

  def scoped?(conditions={})
    return true if self.allow_list
    return false if self.deny_list
  true # otherwise just default to true
  end

end
end
end
