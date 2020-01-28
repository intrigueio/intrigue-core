module Intrigue
module Issue
class MaliciousDomain< BaseIssue

  def self.generate(instance_details={source: "IP"})
    to_return = {
      name: "malicious_domain",
      pretty_name: "Malicious domain related to suspicious activity",
      severity: 3,
      status: "confirmed",
      category: "network",
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
