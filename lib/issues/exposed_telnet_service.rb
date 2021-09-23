module Intrigue
  module Issue
  class ExposedTelnetService < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-25",
        name: "exposed_telnet_service",
        pretty_name: "Exposed Telnet Service",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "A telnet service was found listening on the network.",
        remediation: "Prevent access to this service, utilize a more modern and encrypted alternative like SSH",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end