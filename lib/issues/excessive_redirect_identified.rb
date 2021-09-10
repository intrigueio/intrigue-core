module Intrigue
  module Issue
    class ExecessiveRedirectsIdentified < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-06-20',
          name: 'excessive_redirects_identified',
          pretty_name: 'Excessive redirects identified',
          severity: 5,
          category: 'misconfiguration',
          status: 'confirmed',
          description: 'Excessive redirects were triggered by the request.',
          remediation: 'Confirm if every redirect is required.',
        }.merge!(instance_details)
      end
    end
  end
end
