module Intrigue
module Issue
class WeakServiceIdentified < BaseIssue

  def self.generate(instance_details={})
    {
      name: "weak_service_identified",
      pretty_name: "Weak Service Identified",
      severity: 4,
      category: "application",
      description: "A service known to be weak (lacking encryption) and have more modern alternatives was identified.",
      remediation: "Disable the weak service and replace it with a more secure alternative.",
      affected_software: [ ],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://www.ssh.com/ssh/ftp/server" }
      ]
    }.merge!(instance_details)
  end

end
end
end
