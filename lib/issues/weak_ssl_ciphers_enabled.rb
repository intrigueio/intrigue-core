module Intrigue
  module Issue
  class WeakSslCiphersEnabled < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "weak_ssl_ciphers_enabled",
        pretty_name: "Weak SSL/TLS Cipher Enabled",
        severity: 5,
        category: "misconfiguration",
        status: "confirmed",
        description: "This server is configured to allow a known-weak cipher suite.",
        remediation: "Disable the weak cipher according the the instructions for your web server.",
        affected_software: [ ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://thycotic.com/company/blog/2014/05/16/ssl-beyond-the-basics-part-2-ciphers/" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  