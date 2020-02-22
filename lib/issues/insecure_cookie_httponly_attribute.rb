module Intrigue
  module Issue
  class InsecureCookieHttpOnlyAttribute < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "insecure_cookie_httponly_attribute",
        pretty_name: "Insecure Cookie ('HttpOnly' Attribute)",
        severity: 5,
        category: "application",
        description: "A cookie was found, missing the 'HttpOnly' attribute. HttpOnly is a flag included in a Set-Cookie HTTP response header. Using the HttpOnly flag when generating a cookie helps mitigate the risk of client side script accessing the protected cookie.",
        remediation: "Add the 'httponly' attribute to ensure the cookie is only ever sent via HTTP.",
        affected_software: [ ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://owasp.org/www-community/HttpOnly" },
          { type: "remediations", uri: "https://owasp.org/www-community/HttpOnly" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  