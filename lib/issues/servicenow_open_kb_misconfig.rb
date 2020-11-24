module Intrigue
  module Issue
  class ServicenowOpenKbMisconfig < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-06-05",
        name: "servicenow_open_kb_misconfig",
        pretty_name: "ServiceNow Open KB Misconfig",
        severity: 5,
        status: "confirmed",
        category: "misconfiguration",
        description: "",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://medium.com/@th3g3nt3l/multiple-information-exposed-due-to-misconfigured-service-now-itsm-instances-de7a303ebd56"}
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  