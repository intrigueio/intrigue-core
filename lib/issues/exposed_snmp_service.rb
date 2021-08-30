module Intrigue
  module Issue
  class ExposedSnmpService < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2021-08-30",
        name: "exposed_snmp_service",
        pretty_name: "Exposed SNMP Service",
        severity: 3,
        status: "confirmed",
        category: "leak",
        description: "An SNMP service was found exposed.",
        remediation: "Investigate and determine if this system should be exposed to anonymous users.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end