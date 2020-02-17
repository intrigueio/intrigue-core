module Intrigue
module Issue
class LeakedEmail< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "leaked_email",
      pretty_name: "Leaked Email",
      severity: 3,
      status: "confirmed",
      category: "network",
      description: "Email has been found in a breach",
      remediation: "Users should be notified to reset their passwords and check for suspicious activities related to their accounts",

    }.merge!(instance_details)

  to_return
  end

end
end
end
