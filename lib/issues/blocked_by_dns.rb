module Intrigue
module Issue
class BlockedByDns < BaseIssue

  def self.generate(instance_details={source: "DNS"})

    to_return = {
      added: "2020-01-01",
      pretty_name: "Blocked by DNS Provider",
      name: "blocked_by_dns",
      category: "compromise",
      severity: 4,
      status: "confirmed",
      description: "This host has been detected as compromised, fraudulent, or otherwise harmful and blocked when attempting to resolve. " +
        "Users attempting to resolve this resource through the provider will not be able to reach it.",
      remediation:  "The resource should be investigated for malicious activity. After investigation and cleanup, a notification can " +
        "be sent to the source to have it removed from the block list.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://www.spamtitan.com/web-filtering/how-does-dns-filtering-work/" }
      ]
    }.merge(instance_details)

  to_return
  end

end
end
end