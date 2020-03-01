module Intrigue
module Issue
class Jira2faBypass < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      name: "jira_2fa_bypass",
      pretty_name: "Jira 2FA Bypassable",
      category: "application",
      severity: 3,
      status: "confirmed",
      description: "We detected a jira instance with 2FA configured, but were able to bypass 2FA using the provided link",
      remediation:  "Consult your jira configuration and 2FA provider for instructions on how to prevent this bypass",
      affected_software: [
        { :vendor => "Atlassian", :product => "Jira" }
      ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://community.atlassian.com/t5/Jira-questions/How-to-skip-SSO-for-API/qaq-p/697711" }
      ]
    }.merge(instance_details)
    
  to_return
  end

end
end
end