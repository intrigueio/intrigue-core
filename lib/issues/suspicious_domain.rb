module Intrigue
module Issue
class SuspiciousDomain< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "suspicious_domain",
      pretty_name: "Suspicious Activity Detected",
      severity: 3,
      status: "confirmed",
      category: "reputation",
      description: "This domain has a suspicious activity in the last 48 hours",
      remediation: "This domain should be Investigated before taking blocking actions",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
