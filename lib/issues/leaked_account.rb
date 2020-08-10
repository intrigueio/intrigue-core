module Intrigue
module Issue
class LeakedAccountDetails < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "leaked_account",
      pretty_name: "Leaked Account Detected",
      severity: 2,
      status: "confirmed",
      category: "leak",
      description: "Account found in publicly leaked data.",
      remediation: "Leaked accounts should have their passwords reset and examined for suspicious activities.",
      references: [
        { type: "description", uri: "https://haveibeenpwned.com/"}
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
