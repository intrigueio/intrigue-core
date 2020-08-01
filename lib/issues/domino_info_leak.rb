module Intrigue
  module Issue
  class DominoInfoLeak < BaseIssue
  
    
    def self.generate(instance_details)
      to_return = {
        added: "2020-01-01",
        name: "domino_info_leak",
        pretty_name: "Domino Info Leak",
        severity: 3,
        status: "confirmed",
        category: "network",
        description: "This Domino server exposes sensitive information.",
        remediation: "Adjust the access control settings to disallow this information for anonymous users.",
        affected_software: [
          { :vendor => "Lotus", :product => "Domino" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
          { type: "description", uri: "https://www.netsparker.com/blog/web-security/disable-directory-listing-web-servers/"}
        ],
        # task: handled in ident
      }.merge!(instance_details)
  
    to_return
    end
  
  end
  end
  end
  