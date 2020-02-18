module Intrigue
module Issue
class BlockedByAdBlockPlus < BaseIssue

  def self.generate(instance_details={})

    to_return = {
      pretty_name: "Blocked by AdBlockPlus",
      name: "blocked_by_adblockplus",
      category: "network",
      severity: 5,
      status: "confirmed",
      description: "This website matches one of the rules of AdBlockPlus List, and will be blocked by AdBlockPlus users.",
      remediation:  "The resource should be investigated for malicious activity.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "description", uri: "https://adblockplus.org/getting_started" }
      ]
    }.merge(instance_details)

  to_return
  end

end
end
end
