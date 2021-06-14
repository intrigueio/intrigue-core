module Intrigue
  module Issue
    class WildcardCertificate < BaseIssue
      def self.generate(instance_details={})
        to_return = {
          added: '2021-06-11',
          name: 'wildcard_certificate',
          pretty_name: 'Wildcard Certificate',
          severity: 4,
          status: 'confirmed',
          category: 'misconfiguration',
          description: 'A major risk that applies to both wildcard and multi-domain certificates is that you multiply the scope of any potential issues with the certificate. 
            If the private key is stolen or the certificate expires, this problem now affects every site
            using the wildcard or multi-domain certificate rather than just one',
          remediation: 'Each domain must have a unique certificate that is only valid for its subdomains.',
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: 'description', uri: 'https://www.packetlabs.net/wildcard-certificates/' }
          ]
        }.merge(instance_details)

        to_return
      end
    end
  end
end
