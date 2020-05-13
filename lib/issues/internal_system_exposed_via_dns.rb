module Intrigue
  module Issue
  class InternalSystemExposedViaDns < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "internal_system_exposed_via_dns",
        pretty_name: "Internal System Exposed via DNS",
        severity: 4,
        category: "network",
        status: "confirmed",
        description: "An internal system was identified outside the organization via DNS.",
        remediation: "Investigate if this system should be exposed.",
        references: [] # types: description, remediation, detection_rule, exploit, threat_intel
      }.merge!(instance_details)
    end
  
  end
  end
  end