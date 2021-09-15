module Intrigue
module Issue
class LeakedData < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      added: "2020-01-01",
      name: "leaked_data",
      pretty_name: "Leaked Data Detected",
      severity: 3,
      status: "confirmed",
      category: "leak",
      description: "Related account found leaked",
      remediation: "leaked accounts should be notified to reset their passwords and check for suspicious activities related to their accounts",
      references: [
        { type: "description", uri: "https://haveibeenpwned.com/" }
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
