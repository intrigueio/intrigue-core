module Intrigue
  module Issue
  class DnsNsec3Walk < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "dns_nsec3_walk",
        pretty_name: "DNS NSEC Walk",
        severity: 3,
        status: "confirmed",
        category: "misconfiguration",
        description: "This DNS server is configured with NSEC3 records, allowing the contents to be enumerated through a 'nsec walk' technique.",
        remediation: "Remove DNSSEC NSEC3 records.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://appsecco.com/books/subdomain-enumeration/active_techniques/zone_walking.html" },
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          