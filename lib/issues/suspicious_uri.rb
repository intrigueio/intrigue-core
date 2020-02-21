module Intrigue
module Issue
class SuspiciousUri< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "suspicious_uri",
      pretty_name: "Suspicious Activity Detected",
      severity: 3,
      status: "confirmed",
      category: "reputation",
      description: "This Uri address had suspicious activity detected.",
      remediation: "This Uri address should be Investigated before taking blocking actions",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
