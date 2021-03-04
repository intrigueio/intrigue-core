module Intrigue
    module Issue
    class DNSCAAMissing < BaseIssue

      def self.generate(instance_details={})
        {
          added: "2021-03-04",
          name: "dns_caa_missing",
          pretty_name: "Domain is missing a CAA record",
          severity: 5,
          category: "misconfiguration",
          status: "confirmed",
          description: "DNS Certification Authority Authorization (CAA) is an Internet security policy mechanism which allows domain name holders to indicate to certificat$
          remediation: "Add a CAA record for the domain.",
          references: [ # types: description, remediation, detection_rule, exploit, threat_intel
            { type: "description", uri: "https://en.wikipedia.org/wiki/DNS_Certification_Authority_Authorization" },
            { type: "remediation", uri: "https://sslmate.com/caa/" },
          ],
          check: "tasks/dns_lookup_caa.rb"
        }.merge!(instance_details)
      end

    end
    end
end
