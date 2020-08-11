module Intrigue
  module Issue
  class InvalidCertificateExpirinh < BaseIssue

    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "invalid_certificate_expiring",
        pretty_name: "Expiring Certificate",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "This certificate is going to be expired soon",
        remediation: "Replace the certificate and/or de-provision the service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end

  end
  end
  end
