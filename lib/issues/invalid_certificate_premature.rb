module Intrigue
  module Issue
  class InvalidCertificatePremature < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "invalid_certificate_premature",
        pretty_name: "Invalid (Premature) Certificate",
        severity: 3,
        category: "application",
        status: "confirmed",
        description: "This certificate was found to be not valid until a date in the future",
        remediation: "Replace the certificate and/oor de-provision the service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          