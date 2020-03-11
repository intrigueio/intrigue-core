module Intrigue
  module Issue
  class DevelopmentSystemIdentified < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "development_system_identified",
        pretty_name: "Development System Identified",
        severity: 4,
        category: "network",
        status: "potential",
        description: "A development system was identified outside the organization.",
        remediation: "Investigate if this system should be exposed.",
        references: [] # types: description, remediation, detection_rule, exploit, threat_intel
      }.merge!(instance_details)
    end
  
  end
  end
  end