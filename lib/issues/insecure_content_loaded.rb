module Intrigue
  module Issue
  class InsecureContentLoaded < BaseIssue
  
    def self.generate(instance_details={})
      {
        name: "insecure_content_loaded",
        pretty_name: "Insecure Content Loaded",
        severity: 4,
        category: "application",
        status: "confirmed",
        description: "When a browser requested the page, an external resource was requested over HTTP. This resource could be intercepted by a malicious user and they may be able to take control of the information on the page.",
        remediation: "Investigate the page and ensure all resources are loaded over HTTPS.",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://developers.google.com/web/fundamentals/security/prevent-mixed-content/what-is-mixed-content" }
        ]
      }.merge!(instance_details)
    end
  
  end
  end
  end
  