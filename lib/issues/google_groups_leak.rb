module Intrigue
module Issue
class GoogleGroupsLeak < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "google_groups_leak",
      pretty_name: "Public Google Groups Detected",
      severity: 3,
      status: "confirmed",
      category: "application",
      description: "Enabling public Google Groups can cause sensitive data leakage.",
      remediation: "Review the visibility level of this group in the Google Admin console.",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://support.google.com/a/answer/167427?hl=en" }
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
