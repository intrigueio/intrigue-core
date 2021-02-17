module Intrigue
  module Issue
  class InsecureCookieWideScoped < BaseIssue
  
    def self.generate(instance_details={})
      {
        added: "2020-01-01",
        name: "insecure_cookie_widescoped",
        pretty_name: "Insecure Cookie (Widescoped)",
        severity: 5,
        category: "misconfiguration",
        status: "confirmed",
        description: "A wide scoped cookie can be accessed by applications sharing the same base domain (subdomains) which can result in compromise of the cookie in certain scenarios such as subdomain takeovers, cross-site scripting and more. This issue can become dangerous if said cookie is a session cookie.",
        remediation: "Ensure cookies are properly scoped.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://vulncat.fortify.com/en/detail?id=desc.config.php.cookie_security_overly_broad_session_cookie_domain" },
          { type: "remediation", uri: "https://vulncat.fortify.com/en/detail?id=desc.config.php.cookie_security_overly_broad_session_cookie_domain" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  