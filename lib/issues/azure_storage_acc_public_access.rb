module Intrigue
  module Issue
    class AzureStorageAccountPublicAccess < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2020-09-01',
          name: 'azure_storage_acc_public_access',
          pretty_name: 'Azure Storage Account Allows Public Access',
          severity: 5,
          status: 'potential',
          category: 'misconfiguration',
          # TODO: change the wording in description because it makes it sound like the access is implicit
          # the container can still dictate whether or not acesss blobs & their contents should be public
          description: 'An Azure Storage Account was found to allow public access to its containers and their respective blobs.',
          remediation: 'Investigate whether public access should be allowed.',
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: 'description', uri: 'https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal' }
          ]
        }.merge(instance_details)

      end
    end
  end
end
