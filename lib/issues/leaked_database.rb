module Intrigue
module Issue
class OpenDataBase< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "open_database",
      pretty_name: "Open Database Detected",
      severity: 3,
      status: "confirmed",
      category: "leak",
      description: "Related database found Open",
      remediation: "Open database should not be exposed to the public",
    }.merge!(instance_details)

  to_return
  end

end
end
end
