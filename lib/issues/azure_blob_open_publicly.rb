
module Intrigue
module Issue
class AzureBLOBOpenPublicly < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      added: "2020-01-01",
      name: "azure_blob_open_publicly",
      pretty_name: "Open Azure BLOB",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "An azure blob found open publilcy",
      remediation: "Investigate whether this azure blob should be exposed, and if not, adjust the settings of the Azure BLOB",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal" }
      ]
    }.merge(instance_details)

  to_return
  end

end
end
end
