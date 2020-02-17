module Intrigue
module Issue
class LeakedAccount< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "leaked_account",
      pretty_name: "Leaked Account",
      severity: 4,
      status: "confirmed",
      category: "network",
      description: "Related account found leaked",
      remediation: "leaked accounts should be notified to reset their passwords and check for suspicious activities related to their accounts",

    }.merge!(instance_details)

  to_return
  end

end
end
end
