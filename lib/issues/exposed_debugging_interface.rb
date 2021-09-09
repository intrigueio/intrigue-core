module Intrigue
module Issue
class ExposedDebuggingInterface < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "exposed_debugging_interface",
      pretty_name: "Exposed Debugging Interface",
      severity: 2,
      status: "confirmed",
      category: "misconfiguration",
      description: "A development debugging interface was found exposed, allowing untrusted and authenticated users to perform authenticated actions.",
      remediation: "Disable the interface.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ],
      # task: handled in ident
    }.merge!(instance_details)
  end

end
end
end