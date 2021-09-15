module Intrigue
  module Issue
  class InternalSystemExposedViaDns < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "internal_system_exposed_via_dns",
        pretty_name: "Internal System Exposed via DNS",
        severity: 4,
        category: "misconfiguration",
        status: "confirmed",
        description: "An internal system was identified outside the organization via DNS.",
        remediation: "Investigate if this system should be exposed.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.cisco.com/c/en/us/products/security/what-is-shadow-it.html" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end