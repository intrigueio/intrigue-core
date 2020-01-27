module Intrigue
module Issue
class MaliciousIP< BaseIssue

  def self.generate(instance_details={source: "IP"})
    to_return = {
      name: "malicious_ip",
      pretty_name: "Malicious IP related to suspicious activity",
      severity: 3,
      status: "confirmed",
      category: "network",
      description: "This IP address has a suspicious activity in the last 48 hours",
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
