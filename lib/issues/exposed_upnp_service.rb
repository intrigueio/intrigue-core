module Intrigue
  module Issue
  class ExposedUpnpService < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-09-25",
        name: "exposed_upnp_service",
        pretty_name: "Exposed UPNP Service",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "A UPNP service was found listening on the network.",
        remediation: "Prevent access to this service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ],
        # task: handled in ident
      }.merge!(instance_details)
    end

  end
  end
  end