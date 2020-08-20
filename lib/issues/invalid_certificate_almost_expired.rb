module Intrigue
  module Issue
  class InvalidCertificateAlmostExpired < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-08-20",
        name: "invalid_certificate_almost_expired",
        pretty_name: "(Almost) Expired Certificate",
        severity: 3,
        category: "misconfiguration",
        status: "confirmed",
        description: "This certificate will expire in 30 days or less.",
        remediation: "Replace the certificate and/or de-provision the service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          