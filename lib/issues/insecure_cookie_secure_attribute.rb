module Intrigue
  module Issue
  class InsecureCookieSecureAttribute < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "insecure_cookie_secure_attribute",
        pretty_name: "Insecure Cookie ('Secure' Attribute)",
        severity: 5,
        category: "application",
        description: "A cookie was found, missing the 'secure' attribute",
        remediation: "Add the 'secure' attribute to ensure the cookie is only every sent via TLS.",
        affected_software: [ ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://owasp.org/www-community/controls/SecureFlag" },
          { type: "remediations", uri: "https://owasp.org/www-community/controls/SecureFlag" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  
  
          