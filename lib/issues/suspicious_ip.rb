module Intrigue
module Issue
class SuspiciousIP< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "suspicious_ip",
      pretty_name: "Suspicious Activity Detected",
      severity: 3,
      status: "confirmed",
      category: "reputation",
      description: "This IP address had suspicious activity detected.",
      remediation: "This IP should be Investigated before taking blocking actions",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
