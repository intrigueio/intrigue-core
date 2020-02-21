module Intrigue
module Issue
class Confluence2faBypass < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      pretty_name: "Confluence 2FA Bypass",
      name: "confluence_2fa_bypass",
      category: "application",
      severity: 3,
      status: "application",
      description: "We detected a confluence instance with 2FA configured, but were able to bypass 2FA utilizing the provided link.",
      remediation:  "Consult your confluence configuration and 2FA provider for instructions on how to prevent this bypass",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://community.atlassian.com/t5/Confluence-questions/Bypass-SSO-Confluence/qaq-p/1078755" }
      ]
    }.merge(instance_details)
    
  to_return
  end

end
end
end