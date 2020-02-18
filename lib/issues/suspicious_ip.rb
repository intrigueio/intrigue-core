module Intrigue
module Issue
class SuspiciousIP< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "suspicious_ip",
      pretty_name: "Suspicious IP related to suspicious activity",
      severity: 3,
      status: "confirmed",
      category: "network",
      description: "This IP address has a suspicious activity",
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
