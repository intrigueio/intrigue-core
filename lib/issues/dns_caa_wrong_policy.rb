module Intrigue
  module Issue
    class DNSCAA < BaseIssue
      def self.generate(instance_details = {})
        {
          added: '2021-21-04',
          name: 'dns_caa_wrong_policy',
          pretty_name: 'Domain has an invalid CAA policy',
          severity: 5,
          category: 'misconfiguration',
          status: 'confirmed',
          description: 'CAA information from this domain differs from the information in the certificate.',
          remediation: 'Add a correct CAA record, setting the policy for this domain.',
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: 'description', uri: 'https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization' },
            { type: 'remediation', uri: 'https://sslmate.com/caa/' }
          ],
          check: 'tasks/dns_caa.rb'
        }.merge!(instance_details)
      end
    end
  end
end
