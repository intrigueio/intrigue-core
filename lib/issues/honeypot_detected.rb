module Intrigue
module Issue
class HoneypotDetected< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "honeypot_detected",
      pretty_name: "Honeypot Detected",
      severity: 3,
      status: "confirmed",
      category: "threat",
      description: "This IP has a 100% chance of being a honeypot",
      remediation: "Check whether it is a honeypot or a real control system",
    }.merge!(instance_details)

  to_return
  end

end
end
end
