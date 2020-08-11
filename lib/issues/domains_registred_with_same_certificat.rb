module Intrigue
module Issue
class DomainsRegisteredWithSameCert < BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "domains_registered_with_same_certificate",
      pretty_name: "Domains Registered With Same Certificate",
      severity: 4,
      status: "confirmed",
      category: "misconfig",
      description: "Many domains founded, registered with the same certificate this may lead to asset discovery and easy enumeration by attackers",
      remediation: "Domains must be registered with different certificates for security reasons to avoid exposing all company resources and websites ",
      affected: [],
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
      ]
    }.merge!(instance_details)

  to_return
  end

end
end
end
