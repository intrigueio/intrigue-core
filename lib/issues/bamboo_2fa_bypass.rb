module Intrigue
  module Issue
  class Bamboo2faBypass < BaseIssue
  
    def self.generate(instance_details={})
  
      to_return = {
        name: "bamboo_2fa_bypass",
        pretty_name: "Bamboo 2FA Bypassable",
        category: "application",
        severity: 3,
        status: "confirmed",
        description: "We detected a Bamboo instance with 2FA configured, but were able to bypass 2FA using the provided link",
        remediation:  "Consult your Bamboo configuration and 2FA provider for instructions on how to prevent this bypass",
        affected_software: [
          { :vendor => "Atlassian", :product => "Bamboo" }
        ],
        references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        ]
      }.merge(instance_details)
      
    to_return
    end
  
  end
  end
  end