module Intrigue
  module Issue
    class AzureStorageContainerPublicListing < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-08-09',
          name: 'azure_storage_container_public_listing',
          pretty_name: 'Azure Storage Container Allows Public Listing',
          severity: 2,
          status: 'potential',
          category: 'misconfiguration',
          description: 'An Azure Storage Container has been detected which allows for the blobs to be publicly listed by anonymous users. ',
          remediation: 'Investigate whether the contents of the Azure Storage Container should be allowed to be listed publicly.',
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: 'description', uri: 'https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal' }
          ]
        }.merge!(instance_details)
      end
    end
  end
end
