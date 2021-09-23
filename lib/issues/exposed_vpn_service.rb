module Intrigue
  module Issue
  class ExposedVpnService < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-25",
        name: "exposed_vpn_service",
        pretty_name: "Exposed VPN Service",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "A VPN service was found.",
        remediation: "Determine if this VPN service is expected.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end