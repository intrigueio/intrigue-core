module Intrigue
  module Issue
  class ExposedDatabse < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "exposed_database",
        pretty_name: "Exposed Database",
        severity: 2,
        status: "confirmed",
        category: "leak",
        description: "A database was found exposed.",
        remediation: "Investigate and determine if this system should be exposed to anonymous users.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end