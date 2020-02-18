module Intrigue
module Issue
class SubdomainHijack < BaseIssue

  def self.generate(instance_details={})
    {
      name: "subdomain_hijack",
      pretty_name: "Subdomain Hijacking Detected",
      severity: 2,
      category: "network",
      description:  " This uri appears to be unclaimed on a third party host, meaning," +
                    " there's a DNS record that points to the same address, but it" +
                    " appears to be unclaimed and you should be able to register it with" +
                    " the host, effectively 'hijacking' the domain.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://securitytrails.com/blog/preventing-domain-hijacking-10-steps-to-increase-your-domain-security" }
      ]
    }.merge!(instance_details)
  end

end
end
end
