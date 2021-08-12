module Intrigue
  module Issue
    class AzureStorageBlobPublic < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-08-09',
          name: 'azure_storage_blob_public',
          pretty_name: 'Exposed Azure Storage Blobs',
          severity: 4,
          status: 'potential',
          category: 'misconfiguration',
          description: 'Azure Storage Blobs have been found which can be accessed by anonymous users. ',
          remediation: 'Investigate whether the found blobs are sensitive and restrict acesss if so.',
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: 'description', uri: 'https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal' }
          ]
        }.merge!(instance_details)
      end
    end
  end
end
