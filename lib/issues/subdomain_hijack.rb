module Intrigue
module Issue
class SubdomainHijack < BaseIssue

  def self.generate(instance_details={})
    {
      added: "2020-01-01",
      name: "subdomain_hijack",
      pretty_name: "Subdomain Vulnerable to Takeover (aka Subdomain Hijack)",
      severity: 2,
      category: "dns",
      status: "potential",
      description:  " This uri appears to be unclaimed on a third party host, meaning," +
                    " there's a DNS record on a domain that is in scope, pointing to a third party" +
                    " but it is unclaimed on the third party host and can be registered with" +
                    " the host, allowing users to host malicious content on the domain.",
      references: [ # types: description, remediation, detection_rule, exploit, threat_intel
        { type: "remediation", uri: "https://securitytrails.com/blog/preventing-domain-hijacking-10-steps-to-increase-your-domain-security" }
      ],
      check: "uri_check_subdomain_hijack"
    }.merge!(instance_details)
  end

end
end
end
