module Intrigue
  module Issue
  class InvalidCertificateAlgorithm < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "invalid_certificate_algorithm",
        pretty_name: "Invalid Certificate (Algorithm)",
        severity: 3,
        category: "application",
        status: "confirmed",
        description: "This certificate was found to be with an ineffective algorithm.",
        remediation: "Replace the certificate and/oor de-provision the service",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          