module Intrigue
  module Issue
  class SplunkInfoLeak < BaseIssue

    def self.generate(instance_details)
      to_return = {
        added: "2020-01-01",
        name: "splunk_info_leak",
        pretty_name: "Splunk Info Leak",
        severity: 1,
        status: "confirmed",
        category: "misconfiguration",
        description: "This server is sensitive information on a status page.",
        remediation: "Update the system.",
        affected_software: [
          { :vendor => "Splunk", :product => "Splunk" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)

    to_return
    end

  end
  end
  end
