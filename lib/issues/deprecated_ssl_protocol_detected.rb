module Intrigue
  module Issue
  class DeprecatedSslProtocolDetected < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "deprecated_ssl_protocol_detected",
        pretty_name: "Deprecated SSL/TLS Protocol Detected",
        severity: 5,
        category: "application",
        status: "confirmed",
        description: "This server is configured to allow a deprecated ssl / tls protocol.",
        remediation: "Disable the weak protocol according the the instructions for your web server.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://tools.ietf.org/id/draft-moriarty-tls-oldversions-diediedie-00.html" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  