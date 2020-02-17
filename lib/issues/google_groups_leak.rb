module Intrigue
module Issue
class GoogleGroupsLeakr< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "google_groups_leak",
      pretty_name: "Public Google Groups Enabled!",
      severity: 3,
      status: "confirmed",
      category: "application",
      description: "Public Google Groups settings enabled can cause sensitive data leakage.",
      remediation: "Set the visibility level when you create groups in the Admin console.",
      affected: [],
      references: ["https://support.google.com/a/answer/167427?hl=en" # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
