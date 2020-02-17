module Intrigue
module Issue
class MaliciousIP< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "malicious_file",
      pretty_name: "Malicious File founded",
      severity: 3,
      status: "confirmed",
      category: "network",
      remediation: "This File should be further investigated",

    }.merge!(instance_details)

  to_return
  end

end
end
end
