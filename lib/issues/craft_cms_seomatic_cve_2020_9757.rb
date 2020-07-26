module Intrigue
  module Issue
  class CraftCmsSeomaticCve20209757 < BaseIssue
  
    def self.generate(instance_details)
      to_return = {
        added: "2020-07-26",
        name: "craft_cms_seomatic_cve_2020_9757",
        pretty_name: "Craft CMS SEOmatic < 3.3.0 Server-Side Template Injection",
        severity: 4,
        status: "confirmed",
        category: "application",
        description: "The SEOmatic component before 3.3.0 for Craft CMS allows Server-Side Template Injection that leads to RCE via malformed data to the metacontainers controller.",
        remediation: "Update the component",
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-9757" },
          { type: "description", uri: "https://github.com/giany/CVE/blob/master/CVE-2020-9757.txt" }
        ],
        check: "craft_cms_seomatic_cve_2020_9757"
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
    end
    