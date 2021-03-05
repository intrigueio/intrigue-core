module Intrigue
    module Issue
    class DNSCAA < BaseIssue

      def self.generate(instance_details={})
        {
          added: "2021-03-04",
          name: "dns_caa",
          pretty_name: "Domain is missing a CAA record",
          severity: 5,
          category: "misconfiguration",
          status: "confirmed",
          description: "Any CA is able to generate a certificate for this domain, increasing the risk of exposure if any CA is compromised."
          remediation: "Add a CAA record for the domain.",
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization" },
            { type: "remediation", uri: "https://sslmate.com/caa/" },
          ],
          check: "tasks/dns_caa.rb"
        }.merge!(instance_details)
      end

    end
    end
end
