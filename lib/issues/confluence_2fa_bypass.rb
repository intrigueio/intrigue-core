module Intrigue
module Issue
class Confluence2faBypass < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      added: "2020-01-01",
      pretty_name: "Confluence 2FA Bypassable",
      name: "confluence_2fa_bypass",
      category: "application",
      severity: 3,
      status: "potential",
      description: "We detected a confluence instance with 2FA configured, but were able to bypass 2FA utilizing the provided link.",
      remediation:  "Consult your confluence configuration and 2FA provider for instructions on how to prevent this bypass",
      affected_software: [
        { :vendor => "Atlassian", :product => "Confluence" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://community.atlassian.com/t5/Confluence-questions/Bypass-SSO-Confluence/qaq-p/1078755" }
      ], 
      check: "uri_brute_focused_content"
    }.merge(instance_details)
    
  to_return
  end

end
end
end