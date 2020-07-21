module Intrigue
  module Issue
  class InvalidCertificateExpired < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "invalid_certificate_expired",
        pretty_name: "Expired Certificate",
        severity: 3,
        category: "application",
        status: "confirmed",
        description: "This certificate was found to be expired",
        remediation: "Replace the certificate and/or de-provision the service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          