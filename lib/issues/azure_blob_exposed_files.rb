
module Intrigue
module Issue
class AzureBlobExposedFiles < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      added: "2020-09-01",
      name: "azure_blob_exposed_files",
      pretty_name: "Potential exposed files within an Azure Blob",
      severity: 1,
      status: "potential",
      category: "misconfiguration",
      description: "An azure blob found open publicly with exposed files ",
      remediation: "Investigate whether those files in the azure blob should be exposed, and if it contains critical files, adjust the settings of the Azure Blob",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal" }
      ]
    }.merge(instance_details)

  to_return
  end

end
end
end
